// Updated chat_controller.dart with Image Support
import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_mobile/src/features/messages/data/chat_repository.dart';
import 'package:repairando_mobile/src/features/messages/domain/chat_detail_model.dart';
import 'package:repairando_mobile/src/features/messages/domain/chat_model.dart';
import 'package:repairando_mobile/src/features/messages/domain/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// Repository Provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final repository = ChatRepository();
  ref.onDispose(() {
    repository.dispose();
  });
  return repository;
});

// Current User Provider
final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

// Is Admin Provider
final isAdminProvider = FutureProvider<bool>((ref) async {
  ref.keepAlive();
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  try {
    final response =
        await Supabase.instance.client
            .from('admin')
            .select('userId')
            .eq('userId', user.id)
            .maybeSingle();
    return response != null;
  } catch (e) {
    return false;
  }
});

// Message State
class MessageState {
  final List<Message> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final bool isConnected;

  const MessageState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.isConnected = true,
  });

  MessageState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    bool? isConnected,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

// Chat State
class ChatState {
  final List<ChatWithDetails> chats;
  final bool isLoading;
  final bool isCreatingChat;
  final String? error;

  const ChatState({
    this.chats = const [],
    this.isLoading = false,
    this.isCreatingChat = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatWithDetails>? chats,
    bool? isLoading,
    bool? isCreatingChat,
    String? error,
  }) {
    return ChatState(
      chats: chats ?? this.chats,
      isLoading: isLoading ?? this.isLoading,
      isCreatingChat: isCreatingChat ?? this.isCreatingChat,
      error: error,
    );
  }
}

// Enhanced Message Controller with Image Support
class MessageController extends StateNotifier<MessageState> {
  final ChatRepository _repository;
  final int _chatId;
  StreamSubscription? _messagesSubscription;
  Timer? _retryTimer;
  final Set<String> _optimisticMessages = {}; // Track optimistic messages

  MessageController(this._repository, this._chatId)
    : super(const MessageState()) {
    _initializeMessages();
  }

  void _initializeMessages() {
    if (mounted) {
      state = state.copyWith(isLoading: true, error: null, isConnected: true);
    }

    _watchMessages();
  }

  void _watchMessages() {
    // Cancel existing subscription
    _messagesSubscription?.cancel();
    _retryTimer?.cancel();

    _messagesSubscription = _repository
        .getMessagesStream(_chatId)
        .listen(
          (messages) {
            if (mounted) {
              // Sort messages by created_at to ensure correct order
              final sortedMessages = List<Message>.from(messages);
              sortedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

              // Remove optimistic messages that now have real counterparts
              final realMessageContents =
                  sortedMessages.map((m) => m.content).toSet();
              _optimisticMessages.removeWhere(
                (content) => realMessageContents.contains(content),
              );

              state = state.copyWith(
                messages: sortedMessages,
                error: null,
                isLoading: false,
                isConnected: true,
              );
            }
          },
          onError: (error) {
            if (mounted) {
              state = state.copyWith(
                error: error.toString(),
                isLoading: false,
                isConnected: false,
              );

              // Retry connection after 3 seconds
              _retryTimer = Timer(const Duration(seconds: 3), () {
                _watchMessages();
              });
            }
          },
        );
  }

  Future<void> sendMessage({
    required String senderId,
    required MessageSenderType senderType,
    required String content,
    String messageType = 'text',
  }) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) return;

    if (!_isValidUUID(senderId)) {
      throw Exception('Invalid sender ID format');
    }

    if (mounted) {
      state = state.copyWith(isSending: true, error: null);
    }

    _optimisticMessages.add(trimmedContent);

    try {
      // Create optimistic message for immediate UI update
      final nextMessageId = _generateOptimisticId();
      final optimisticMessage = Message(
        id: nextMessageId,
        chatId: _chatId,
        senderId: senderId,
        senderType: senderType,
        content: trimmedContent,
        messageType: messageType,
        createdAt: DateTime.now(),
        isRead: false,
        readAt: null,
      );

      if (mounted) {
        final currentMessages = List<Message>.from(state.messages)
          ..add(optimisticMessage);
        currentMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        state = state.copyWith(messages: currentMessages, isSending: false);
      }

      await _repository.sendMessage(
        chatId: _chatId,
        senderId: senderId,
        senderType: senderType,
        content: trimmedContent,
        messageType: messageType,
      );
    } catch (e) {
      if (mounted) {
        // Remove optimistic message on error
        final currentMessages = List<Message>.from(state.messages);
        currentMessages.removeWhere((msg) => msg.content == trimmedContent);

        _optimisticMessages.remove(trimmedContent);

        state = state.copyWith(
          messages: currentMessages,
          isSending: false,
          error: e.toString(),
        );
      }
      rethrow;
    }
  }

  Future<void> sendImageMessage({
    required String senderId,
    required MessageSenderType senderType,
    required String imagePath,
  }) async {
    if (!_isValidUUID(senderId)) {
      throw Exception('Invalid sender ID format');
    }

    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      throw Exception('Image file does not exist');
    }

    if (mounted) {
      state = state.copyWith(isSending: true, error: null);
    }

    try {
      // Upload image to Supabase Storage
      final fileName =
          'chat_$_chatId/${DateTime.now().millisecondsSinceEpoch}_${senderId.substring(0, 8)}.jpg';

      await Supabase.instance.client.storage
          .from('chat-images')
          .upload(fileName, imageFile);

      // Get public URL
      final imageUrl = Supabase.instance.client.storage
          .from('chat-images')
          .getPublicUrl(fileName);

      // Create optimistic message with image URL
      final nextMessageId = _generateOptimisticId();
      final optimisticMessage = Message(
        id: nextMessageId,
        chatId: _chatId,
        senderId: senderId,
        senderType: senderType,
        content: imageUrl,
        messageType: 'image',
        createdAt: DateTime.now(),
        isRead: false,
        readAt: null,
      );

      if (mounted) {
        final currentMessages = List<Message>.from(state.messages)
          ..add(optimisticMessage);
        currentMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        state = state.copyWith(messages: currentMessages, isSending: false);
      }

      // Send message with image URL
      await _repository.sendMessage(
        chatId: _chatId,
        senderId: senderId,
        senderType: senderType,
        content: imageUrl,
        messageType: 'image',
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isSending: false,
          error: 'Failed to send image: ${e.toString()}',
        );
      }
      rethrow;
    }
  }

  Future<void> sendPdfMessage({
    required String senderId,
    required MessageSenderType senderType,
    required String pdfPath,
    required String fileName,
  }) async {
    print('🔍 PDF Upload Debug - Starting...');
    print('📄 PDF Path: $pdfPath');
    print('📄 File Name: $fileName');
    print('👤 Sender ID: $senderId');
    print('💬 Chat ID: $_chatId');
    
    if (!_isValidUUID(senderId)) {
      print('❌ Invalid sender ID format');
      throw Exception('Invalid sender ID format');
    }

    final pdfFile = File(pdfPath);
    final fileExists = await pdfFile.exists();
    print('📁 File exists: $fileExists');
    
    if (!fileExists) {
      print('❌ PDF file does not exist at path: $pdfPath');
      throw Exception('PDF file does not exist');
    }

    // Get file size
    final fileSize = await pdfFile.length();
    print('📊 File size: ${fileSize} bytes (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');

    if (mounted) {
      state = state.copyWith(isSending: true, error: null);
      print('🔄 State updated: isSending = true');
    }

    try {
      // Sanitize filename to remove special characters
      final sanitizedFileName = _sanitizeFileName(fileName);
      print('🧹 Original filename: $fileName');
      print('🧹 Sanitized filename: $sanitizedFileName');
      
      // Upload PDF to Supabase Storage
      final storageFileName =
          'chat_$_chatId/${DateTime.now().millisecondsSinceEpoch}_${senderId.substring(0, 8)}_$sanitizedFileName';
      
      print('📤 Storage file name: $storageFileName');
      print('🪣 Bucket: chat-images');
      print('⏳ Starting upload...');

      final uploadResult = await Supabase.instance.client.storage
          .from('chat-images')
          .upload(storageFileName, pdfFile);
      
      print('✅ Upload successful!');
      print('📋 Upload result: $uploadResult');

      // Get public URL
      final pdfUrl = Supabase.instance.client.storage
          .from('chat-images')
          .getPublicUrl(storageFileName);
      
      print('🔗 PDF URL: $pdfUrl');

      // Create optimistic message with PDF URL
      print('📝 Creating optimistic message...');
      final nextMessageId = _generateOptimisticId();
      final optimisticMessage = Message(
        id: nextMessageId,
        chatId: _chatId,
        senderId: senderId,
        senderType: senderType,
        content: pdfUrl,
        messageType: 'pdf',
        createdAt: DateTime.now(),
        isRead: false,
        readAt: null,
      );
      print('✅ Optimistic message created with ID: $nextMessageId');

      if (mounted) {
        print('🔄 Adding message to UI...');
        final currentMessages = List<Message>.from(state.messages)
          ..add(optimisticMessage);
        currentMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        state = state.copyWith(messages: currentMessages, isSending: false);
        print('✅ Message added to UI, total messages: ${currentMessages.length}');
      }

      // Send message with PDF URL
      print('📤 Sending message to repository...');
      await _repository.sendMessage(
        chatId: _chatId,
        senderId: senderId,
        senderType: senderType,
        content: pdfUrl,
        messageType: 'pdf',
      );
      print('✅ PDF message sent successfully!');
    } catch (e) {
      print('❌ Error during PDF upload/send:');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error message: ${e.toString()}');
      print('❌ Stack trace: ${StackTrace.current}');
      
      if (mounted) {
        state = state.copyWith(
          isSending: false,
          error: 'Failed to send PDF: ${e.toString()}',
        );
        print('🔄 State updated with error');
      }
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String userId) async {
    if (!_isValidUUID(userId)) {
      return;
    }

    try {
      await _repository.markMessagesAsRead(_chatId, userId);
    } catch (e) {}
  }

  void retryConnection() {
    if (mounted) {
      state = state.copyWith(isConnected: true, error: null);
    }
    _watchMessages();
  }

  int _generateOptimisticId() {
    // Generate a negative ID for optimistic messages to avoid conflicts
    return -DateTime.now().millisecondsSinceEpoch;
  }

  bool _isValidUUID(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(uuid);
  }

  String _sanitizeFileName(String fileName) {
    // Remove or replace special characters that can cause issues in storage keys
    return fileName
        .replaceAll(RegExp(r'[^\w\s\-_\.]'), '_') // Replace special chars with underscore
        .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscore
        .replaceAll(RegExp(r'_+'), '_') // Replace multiple underscores with single
        .replaceAll(RegExp(r'^_|_$'), ''); // Remove leading/trailing underscores
  }

  void clearError() {
    if (mounted) {
      state = state.copyWith(error: null);
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _retryTimer?.cancel();
    _optimisticMessages.clear();
    super.dispose();
  }
}

// Chat Controller with Real-time Streams
class ChatController extends StateNotifier<ChatState> {
  final ChatRepository _repository;
  final String? _userId;
  final bool _isAdmin;
  StreamSubscription? _chatsSubscription;
  Timer? _retryTimer;

  ChatController(this._repository, this._userId, this._isAdmin)
    : super(const ChatState()) {
    if (_userId != null) {
      _initializeChats();
    }
  }

  void _initializeChats() {
    if (mounted) {
      state = state.copyWith(isLoading: true, error: null);
    }

    _watchChats();
  }

  void _watchChats() {
    if (_userId == null) return;

    // Cancel existing subscription
    _chatsSubscription?.cancel();
    _retryTimer?.cancel();

    _chatsSubscription = _repository
        .getChatsStream(_userId, _isAdmin)
        .listen(
          (chats) {
            if (mounted) {
              state = state.copyWith(
                chats: chats,
                error: null,
                isLoading: false,
              );
            }
          },
          onError: (error) {
            if (mounted) {
              state = state.copyWith(error: error.toString(), isLoading: false);

              // Retry connection after 5 seconds
              _retryTimer = Timer(const Duration(seconds: 5), () {
                _watchChats();
              });
            }
          },
        );
  }

  Future<void> fetchChats() async {
    if (_userId == null) return;

    if (mounted) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final chats = await _repository.getChats(_userId, _isAdmin);
      if (mounted) {
        state = state.copyWith(chats: chats, isLoading: false);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  // Create a new chat
  Future<Chat> createChat(String customerId, String adminId) async {
    if (mounted) {
      state = state.copyWith(isCreatingChat: true, error: null);
    }

    try {
      final chat = await _repository.createChat(customerId, adminId);

      if (mounted) {
        state = state.copyWith(isCreatingChat: false);
      }

      return chat;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isCreatingChat: false, error: e.toString());
      }
      rethrow;
    }
  }

  // Find existing chat
  Future<Chat?> findExistingChat(
    String userId,
    String otherUserId,
    bool isCurrentUserAdmin,
  ) async {
    try {
      return await _repository.findExistingChat(
        userId,
        otherUserId,
        isCurrentUserAdmin,
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
      return null;
    }
  }

  // Get or create chat for appointment
  Future<Chat?> getOrCreateChatForAppointment(String appointmentId) async {
    if (mounted) {
      state = state.copyWith(isCreatingChat: true, error: null);
    }

    try {
      final chat = await _repository.getOrCreateChatForAppointment(
        appointmentId,
      );

      if (mounted) {
        state = state.copyWith(isCreatingChat: false);
      }

      return chat;
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('Appointment not found')) {
        errorMessage =
            'The appointment could not be found. Please check the appointment ID.';
      } else if (e.toString().contains('Invalid appointment ID format')) {
        errorMessage = 'Invalid appointment ID format.';
      } else if (e.toString().contains('Missing required data')) {
        errorMessage = 'The appointment data is incomplete.';
      } else {
        errorMessage = 'Failed to create chat: ${e.toString()}';
      }

      if (mounted) {
        state = state.copyWith(isCreatingChat: false, error: errorMessage);
      }

      return null;
    }
  }

  // Retry connection
  void retryConnection() {
    if (mounted) {
      state = state.copyWith(error: null);
    }
    _watchChats();
  }

  // Clear error
  void clearError() {
    if (mounted) {
      state = state.copyWith(error: null);
    }
  }

  // Refresh chats manually
  Future<void> refreshChats() async {
    await fetchChats();
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }
}

// Providers
final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>(
  (ref) {
    ref.keepAlive();
    final repository = ref.watch(chatRepositoryProvider);
    final user = ref.watch(currentUserProvider);
    final isAdminAsync = ref.watch(isAdminProvider);

    final isAdmin = isAdminAsync.when(
      data: (value) => value,
      loading: () => false,
      error: (_, __) => false,
    );

    return ChatController(repository, user?.id, isAdmin);
  },
);

final messageControllerProvider =
    StateNotifierProvider.family<MessageController, MessageState, int>((
      ref,
      chatId,
    ) {
      final repository = ref.watch(chatRepositoryProvider);
      return MessageController(repository, chatId);
    });

// Utility provider for getting current user's admin status
final currentUserAdminStatusProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final isAdminResult = await ref.watch(isAdminProvider.future);
  return isAdminResult;
});

// Provider for getting a specific chat
final specificChatProvider = FutureProvider.family<Chat?, int>((
  ref,
  chatId,
) async {
  try {
    final chats = ref.watch(chatControllerProvider).chats;
    return chats.firstOrNull?.chat.id == chatId
        ? chats.firstOrNull?.chat
        : null;
  } catch (e) {
    return null;
  }
});

// Extension for firstOrNull
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
