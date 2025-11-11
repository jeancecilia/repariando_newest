import 'package:repairando_web/src/features/home/domain/chat_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class ChatRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all chats for admin with customer names using JOIN
  Stream<List<Chat>> getChatsStream() {
    return _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .map((rows) async* {
          // For each chat, fetch customer details
          List<Chat> chats = [];
          for (var row in rows) {
            try {
              // Fetch customer details
              final customerResponse =
                  await _supabase
                      .from('customers')
                      .select('name, email')
                      .eq('id', row['customer_id'])
                      .single();

              // Add customer info to the row
              row['customers'] = customerResponse;
              chats.add(Chat.fromJson(row));
            } catch (e) {
              // If customer not found, still add the chat with unknown user
              row['customers'] = {'name': 'Unknown User', 'email': ''};
              chats.add(Chat.fromJson(row));
            }
          }
          yield chats;
        })
        .asyncExpand((chatsFuture) => chatsFuture);
  }

  // Alternative approach using RPC (Recommended for better performance)
  Stream<List<Chat>> getChatsStreamWithRPC() {
    return _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .asyncMap((rows) async {
          if (rows.isEmpty) return <Chat>[];

          // Get all customer IDs
          final customerIds = rows.map((row) => row['customer_id']).toList();

          // Fetch all customers in one query
          final customersResponse = await _supabase
              .from('customers')
              .select('id, name, email')
              .inFilter('id', customerIds);
          // Create a map for quick lookup
          final customersMap = <String, Map<String, dynamic>>{};
          for (var customer in customersResponse) {
            customersMap[customer['id']] = customer;
          }

          // Map chats with customer info
          return rows.map((row) {
            final customer = customersMap[row['customer_id']];
            row['customers'] =
                customer ?? {'name': 'Unknown User', 'email': ''};
            return Chat.fromJson(row);
          }).toList();
        });
  }

  // Get messages for a specific chat with real-time updates
  Stream<List<Message>> getMessagesStream(int chatId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true) // Keep chronological order
        .map((data) => data.map((json) => Message.fromJson(json)).toList());
  }

  // Upload image to Supabase storage
  Future<String?> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
    required int chatId,
  }) async {
    try {
      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Clean the filename: remove spaces, special characters, and sanitize
      final cleanFileName =
          fileName
              .replaceAll(' ', '_') // Replace spaces with underscores
              .replaceAll(
                RegExp(r'[^\w\-_\.]'),
                '',
              ) // Remove special chars except dash, underscore, dot
              .toLowerCase(); // Convert to lowercase for consistency

      final uniqueFileName = '${chatId}_${timestamp}_$cleanFileName';

      // Upload to chat-images bucket
      final response = await _supabase.storage
          .from('chat-images')
          .uploadBinary(uniqueFileName, imageBytes);

      if (response.isEmpty) {
        throw Exception('Upload failed: No response');
      }

      // Get public URL
      final imageUrl = _supabase.storage
          .from('chat-images')
          .getPublicUrl(uniqueFileName);

      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Send a message with proper chat updates
  Future<Message?> sendMessage({
    required int chatId,
    required String senderId,
    required String senderType,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      final now = DateTime.now();

      // Insert message
      final response =
          await _supabase
              .from('messages')
              .insert({
                'chat_id': chatId,
                'sender_id': senderId,
                'sender_type': senderType,
                'message_type': messageType,
                'content': content,
                'is_read':
                    senderType == 'admin', // Admin messages are read by default
                'created_at': now.toIso8601String(),
              })
              .select()
              .single();

      // Update chat's last message and timestamp
      String lastMessageText = content;
      if (messageType == 'image') {
        lastMessageText = '📷 Image';
      } else if (messageType == 'pdf') {
        lastMessageText = '📄 PDF Document';
      }

      await updateChatLastMessage(chatId, lastMessageText, now);

      return Message.fromJson(response);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Send image message
  Future<Message?> sendImageMessage({
    required int chatId,
    required String senderId,
    required String senderType,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      // First upload the image
      final imageUrl = await uploadImage(
        imageBytes: imageBytes,
        fileName: fileName,
        chatId: chatId,
      );

      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      // Then send the message with image URL
      return await sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderType: senderType,
        content: imageUrl,
        messageType: 'image',
      );
    } catch (e) {
      throw Exception('Failed to send image message: $e');
    }
  }

  // Upload PDF to Supabase storage
  Future<String?> uploadPdf({
    required Uint8List pdfBytes,
    required String fileName,
    required int chatId,
  }) async {
    try {
      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Clean the filename: remove spaces, special characters, and sanitize
      final cleanFileName =
          fileName
              .replaceAll(' ', '_') // Replace spaces with underscores
              .replaceAll(
                RegExp(r'[^\w\-_\.]'),
                '',
              ) // Remove special chars except dash, underscore, dot
              .toLowerCase(); // Convert to lowercase for consistency

      final uniqueFileName = '${chatId}_${timestamp}_$cleanFileName';

      // Upload to chat-images bucket (same as images)
      final response = await _supabase.storage
          .from('chat-images')
          .uploadBinary(uniqueFileName, pdfBytes);

      if (response.isEmpty) {
        throw Exception('Upload failed: No response');
      }

      // Get public URL
      final pdfUrl = _supabase.storage
          .from('chat-images')
          .getPublicUrl(uniqueFileName);

      return pdfUrl;
    } catch (e) {
      throw Exception('Failed to upload PDF: $e');
    }
  }

  // Send PDF message
  Future<Message?> sendPdfMessage({
    required int chatId,
    required String senderId,
    required String senderType,
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    try {
      // First upload the PDF
      final pdfUrl = await uploadPdf(
        pdfBytes: pdfBytes,
        fileName: fileName,
        chatId: chatId,
      );

      if (pdfUrl == null) {
        throw Exception('Failed to upload PDF');
      }

      // Then send the message with PDF URL
      return await sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderType: senderType,
        content: pdfUrl,
        messageType: 'pdf',
      );
    } catch (e) {
      throw Exception('Failed to send PDF message: $e');
    }
  }

  // Update chat last message info
  Future<void> updateChatLastMessage(
    int chatId,
    String lastMessage,
    DateTime timestamp,
  ) async {
    try {
      await _supabase
          .from('chats')
          .update({
            'last_message': lastMessage,
            'last_message_at': timestamp.toIso8601String(),
          })
          .eq('id', chatId);
    } catch (e) {
      print('Failed to update chat: $e');
    }
  }

  // Mark messages as read and update unread count
  Future<void> markMessagesAsRead(int chatId, String currentUserId) async {
    try {
      final now = DateTime.now();

      // Mark messages as read
      await _supabase
          .from('messages')
          .update({'is_read': true, 'read_at': now.toIso8601String()})
          .eq('chat_id', chatId)
          .neq('sender_id', currentUserId)
          .eq('is_read', false);
    } catch (e) {
      print('Failed to mark messages as read: $e');
    }
  }

  // Get unread count for a chat
  Future<int> getUnreadCount(int chatId, String currentUserId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('id')
          .eq('chat_id', chatId)
          .neq('sender_id', currentUserId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // Get chat with customer info
  Future<Chat?> getChatById(int chatId) async {
    try {
      final chatResponse =
          await _supabase.from('chats').select('*').eq('id', chatId).single();

      // Fetch customer details
      final customerResponse =
          await _supabase
              .from('customers')
              .select('name, email')
              .eq('id', chatResponse['customer_id'])
              .single();

      chatResponse['customers'] = customerResponse;
      return Chat.fromJson(chatResponse);
    } catch (e) {
      return null;
    }
  }

  // Create a new chat
  Future<Chat?> createChat(String customerId, String adminId) async {
    try {
      final response =
          await _supabase
              .from('chats')
              .insert({
                'customer_id': customerId,
                'admin_id': adminId,
                'created_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      // Fetch customer details
      final customerResponse =
          await _supabase
              .from('customers')
              .select('name, email')
              .eq('id', customerId)
              .single();

      response['customers'] = customerResponse;
      return Chat.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  // Subscribe to real-time changes for a specific chat
  RealtimeChannel subscribeToChat(
    int chatId,
    Function(List<Message>) onMessagesChanged,
  ) {
    return _supabase
        .channel('messages:$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            // Refresh messages when new message is inserted
            getMessagesStream(chatId).first.then(onMessagesChanged);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            // Refresh messages when message is updated (e.g., marked as read)
            getMessagesStream(chatId).first.then(onMessagesChanged);
          },
        )
        .subscribe();
  }

  // Subscribe to real-time chat list changes
  RealtimeChannel subscribeToChats(Function() onChatsChanged) {
    return _supabase
        .channel('chats')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chats',
          callback: (payload) {
            onChatsChanged();
          },
        )
        .subscribe();
  }

  Future<Chat?> getExistingChat(String customerId, String adminId) async {
    try {
      final response =
          await _supabase
              .from('chats')
              .select('*')
              .eq('customer_id', customerId)
              .eq('admin_id', adminId)
              .maybeSingle();

      if (response == null) return null;

      // Fetch customer details
      final customerResponse =
          await _supabase
              .from('customers')
              .select('name, email')
              .eq('id', customerId)
              .single();

      response['customers'] = customerResponse;
      return Chat.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Create or get existing chat
  Future<Chat?> createOrGetChat(String customerId, String adminId) async {
    try {
      // First check if chat already exists
      final existingChat = await getExistingChat(customerId, adminId);
      if (existingChat != null) {
        return existingChat;
      }

      // Create new chat if doesn't exist
      return await createChat(customerId, adminId);
    } catch (e) {
      throw Exception('Failed to create or get chat: $e');
    }
  }

  // Send initial message when starting a chat
  Future<Message?> sendInitialMessage({
    required int chatId,
    required String senderId,
    required String content,
  }) async {
    return await sendMessage(
      chatId: chatId,
      senderId: senderId,
      senderType: 'admin',
      content: content,
      messageType: 'text',
    );
  }
}
