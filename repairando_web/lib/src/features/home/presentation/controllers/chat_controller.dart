import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_web/src/features/home/data/chat_repsitory.dart';
import 'package:repairando_web/src/features/home/domain/chat_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

// Repository Provider
final messagesRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

// Chats Stream Provider with customer names
final chatsStreamProvider = StreamProvider<List<Chat>>((ref) {
  final repository = ref.read(messagesRepositoryProvider);
  // Use the optimized version with RPC for better performance
  return repository.getChatsStreamWithRPC();
});

// Messages Stream Provider for specific chat
final messagesStreamProvider = StreamProvider.family<List<Message>, int>((
  ref,
  chatId,
) {
  final repository = ref.read(messagesRepositoryProvider);
  return repository.getMessagesStream(chatId);
});

// Real-time Chat Subscription Provider
final chatSubscriptionProvider = Provider.family<RealtimeChannel?, int?>((
  ref,
  chatId,
) {
  if (chatId == null) return null;

  final repository = ref.read(messagesRepositoryProvider);

  return repository.subscribeToChat(chatId, (messages) {
    // Invalidate the messages stream to trigger refresh
    ref.invalidate(messagesStreamProvider(chatId));
  });
});

// Real-time Chats List Subscription Provider
final chatsListSubscriptionProvider = Provider<RealtimeChannel>((ref) {
  final repository = ref.read(messagesRepositoryProvider);

  return repository.subscribeToChats(() {
    // Invalidate the chats stream to trigger refresh
    ref.invalidate(chatsStreamProvider);
  });
});

// Messages Controller
class MessagesController extends StateNotifier<AsyncValue<void>> {
  final ChatRepository _repository;
  final Ref _ref;

  MessagesController(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  Future<void> sendMessage({
    required int chatId,
    required String senderId,
    required String senderType,
    required String content,
    String messageType = 'text',
  }) async {
    state = const AsyncValue.loading();

    try {
      await _repository.sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderType: senderType,
        content: content.trim(),
        messageType: messageType,
      );

      state = const AsyncValue.data(null);

      // Refresh both messages and chats streams
      _ref.invalidate(messagesStreamProvider(chatId));
      _ref.invalidate(chatsStreamProvider);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Send image message
  Future<void> sendImageMessage({
    required int chatId,
    required String senderId,
    required String senderType,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _repository.sendImageMessage(
        chatId: chatId,
        senderId: senderId,
        senderType: senderType,
        imageBytes: imageBytes,
        fileName: fileName,
      );

      state = const AsyncValue.data(null);

      // Refresh both messages and chats streams
      _ref.invalidate(messagesStreamProvider(chatId));
      _ref.invalidate(chatsStreamProvider);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Send PDF message
  Future<void> sendPdfMessage({
    required int chatId,
    required String senderId,
    required String senderType,
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _repository.sendPdfMessage(
        chatId: chatId,
        senderId: senderId,
        senderType: senderType,
        pdfBytes: pdfBytes,
        fileName: fileName,
      );

      state = const AsyncValue.data(null);

      // Refresh both messages and chats streams
      _ref.invalidate(messagesStreamProvider(chatId));
      _ref.invalidate(chatsStreamProvider);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> markMessagesAsRead(int chatId, String currentUserId) async {
    try {
      await _repository.markMessagesAsRead(chatId, currentUserId);

      // Refresh chats to update unread count
      _ref.invalidate(chatsStreamProvider);
    } catch (e) {
      // Handle error silently for read receipts
      print('Failed to mark messages as read: $e');
    }
  }

  Future<Chat?> getChatById(int chatId) async {
    try {
      return await _repository.getChatById(chatId);
    } catch (e) {
      return null;
    }
  }

  Future<int> getUnreadCount(int chatId, String currentUserId) async {
    try {
      return await _repository.getUnreadCount(chatId, currentUserId);
    } catch (e) {
      return 0;
    }
  }

  Future<Chat?> createChat(String customerId, String adminId) async {
    try {
      final chat = await _repository.createChat(customerId, adminId);

      // Refresh chats list
      _ref.invalidate(chatsStreamProvider);

      return chat;
    } catch (e) {
      return null;
    }
  }

  // Method to handle real-time subscription lifecycle
  void subscribeToRealTimeUpdates(int? selectedChatId) {
    if (selectedChatId != null) {
      // Subscribe to specific chat updates
      _ref.read(chatSubscriptionProvider(selectedChatId));
    }

    // Always subscribe to chats list updates
    _ref.read(chatsListSubscriptionProvider);
  }

  void unsubscribeFromRealTimeUpdates(int? chatId) {
    try {
      if (chatId != null) {
        final subscription = _ref.read(chatSubscriptionProvider(chatId));
        subscription?.unsubscribe();
      }
    } catch (e) {
      print('Failed to unsubscribe from real-time updates: $e');
    }
  }

  Future<Chat?> initiateChatWithCustomerId({
    required String customerId,
    required String currentUserId,
    String? initialMessage,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Create or get existing chat
      final chat = await _repository.createOrGetChat(customerId, currentUserId);

      if (chat == null) {
        state = AsyncValue.error('Failed to create chat', StackTrace.current);
        return null;
      }

      // Send initial message if provided
      if (initialMessage != null && initialMessage.trim().isNotEmpty) {
        await _repository.sendInitialMessage(
          chatId: chat.id,
          senderId: currentUserId,
          content: initialMessage.trim(),
        );
      }

      state = const AsyncValue.data(null);

      // Refresh streams
      _ref.invalidate(chatsStreamProvider);
      _ref.invalidate(messagesStreamProvider(chat.id));

      return chat;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  // Initiate chat from appointment data
  Future<Chat?> initiateChatFromAppointment({
    required dynamic appointment,
    required String currentUserId,
    String? customMessage,
  }) async {
    try {
      // Extract customer ID from appointment
      String? customerId;

      if (appointment is Map<String, dynamic>) {
        final customer = appointment['customer'];
        if (customer is Map<String, dynamic>) {
          customerId = customer['id']?.toString();
        } else if (customer != null) {
          customerId = customer.id?.toString();
        }
      } else {
        customerId = appointment.customer?.id?.toString();
      }

      if (customerId == null || customerId.isEmpty) {
        throw Exception('Customer ID not found in appointment');
      }

      // Generate default message if not provided
      String initialMessage =
          customMessage ??
          'Hello! I\'m reaching out regarding your appointment.';

      return await initiateChatWithCustomerId(
        customerId: customerId,
        currentUserId: currentUserId,
        initialMessage: initialMessage,
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  // Quick initiate chat (for simple use cases)
  Future<int?> quickInitiateChat({
    required String customerId,
    required String currentUserId,
  }) async {
    try {
      final chat = await initiateChatWithCustomerId(
        customerId: customerId,
        currentUserId: currentUserId,
      );
      return chat?.id;
    } catch (e) {
      return null;
    }
  }
}

// Messages Controller Provider
final messagesControllerProvider =
    StateNotifierProvider<MessagesController, AsyncValue<void>>((ref) {
      final repository = ref.read(messagesRepositoryProvider);
      return MessagesController(repository, ref);
    });

// Provider for current user ID
final currentUserProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

// Provider to get current user's unread message count across all chats
final totalUnreadCountProvider = Provider<AsyncValue<int>>((ref) {
  final currentUserId = ref.watch(currentUserProvider);
  final chatsAsync = ref.watch(chatsStreamProvider);

  if (currentUserId == null) {
    return const AsyncValue.data(0);
  }

  return chatsAsync.when(
    data: (chats) {
      final totalUnread = chats.fold<int>(
        0,
        (sum, chat) => sum + chat.unreadCount,
      );
      return AsyncValue.data(totalUnread);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});
