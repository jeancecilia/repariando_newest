// Updated Chat Repository - chat_repository.dart
import 'package:repairando_mobile/src/features/messages/domain/chat_detail_model.dart';
import 'package:repairando_mobile/src/features/messages/domain/chat_model.dart';
import 'package:repairando_mobile/src/features/messages/domain/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class ChatRepository {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // Store active subscriptions to manage them properly
  final Map<String, RealtimeChannel> _activeSubscriptions = {};
  final Map<String, StreamController> _activeControllers = {};

  // Get chats for current user with proper admin/customer info
  Future<List<ChatWithDetails>> getChats(String userId, bool isAdmin) async {
    try {
      List<Map<String, dynamic>> chatsData;

      if (isAdmin) {
        chatsData = await _supabaseClient
            .from('chats')
            .select('*')
            .eq('admin_id', userId)
            .order('last_message_at', ascending: false);
      } else {
        chatsData = await _supabaseClient
            .from('chats')
            .select('*')
            .eq('customer_id', userId)
            .order('last_message_at', ascending: false);
      }

      List<ChatWithDetails> chatDetails = [];

      for (var chatData in chatsData) {
        final chat = Chat.fromJson(chatData);

        String otherUserName = 'Unknown User';
        String? otherUserImage;

        if (isAdmin) {
          // Fetch customer details
          try {
            final customerResponse =
                await _supabaseClient
                    .from('customers')
                    .select('name, email, profile_image')
                    .eq('id', chat.customerId)
                    .single();

            otherUserName = customerResponse['name'] ?? 'Customer';
            otherUserImage = customerResponse['profile_image'];
          } catch (e) {
            otherUserName = 'Customer';
          }
        } else {
          // Fetch admin details - Fixed field name to match database schema
          try {
            final adminResponse =
                await _supabaseClient
                    .from('admin')
                    .select('workshop_name, email, profile_image')
                    .eq(
                      'userId',
                      chat.adminId!,
                    ) // Changed from 'userId' to 'userid'
                    .single();

            otherUserName = adminResponse['workshop_name'];
            otherUserImage = adminResponse['profile_image'];
          } catch (e) {
            otherUserName = 'Workshop';
          }
        }

        int unreadCount = 0;
        try {
          final unreadMessages = await _supabaseClient
              .from('messages')
              .select('id')
              .eq('chat_id', chat.id)
              .neq('sender_id', userId)
              .eq('is_read', false);

          unreadCount = unreadMessages.length;
        } catch (e) {}

        chatDetails.add(
          ChatWithDetails(
            chat: chat,
            otherUserName: otherUserName,
            otherUserImage: otherUserImage,
            unreadCount: unreadCount,
          ),
        );
      }

      return chatDetails;
    } catch (e) {
      throw Exception('Failed to fetch chats: $e');
    }
  }

  // Real-time stream for chats with proper user info
  Stream<List<ChatWithDetails>> getChatsStream(String userId, bool isAdmin) {
    final streamKey = 'chats_$userId';

    // Cancel existing stream
    _activeSubscriptions[streamKey]?.unsubscribe();
    _activeControllers[streamKey]?.close();

    final controller = StreamController<List<ChatWithDetails>>.broadcast();
    _activeControllers[streamKey] = controller;

    // Fetch initial chats
    _fetchAndEmitChats(userId, isAdmin, controller);

    // Set up real-time subscription
    final String filterField = isAdmin ? 'admin_id' : 'customer_id';

    final chatsChannel =
        _supabaseClient
            .channel('chats_$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'chats',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: filterField,
                value: userId,
              ),
              callback: (payload) {
                _fetchAndEmitChats(userId, isAdmin, controller);
              },
            )
            .subscribe();

    _activeSubscriptions[streamKey] = chatsChannel;

    // Clean up when stream is closed
    controller.onCancel = () {
      chatsChannel.unsubscribe();
      _activeSubscriptions.remove(streamKey);
      _activeControllers.remove(streamKey);
    };

    return controller.stream;
  }

  // Helper method to fetch and emit chats
  void _fetchAndEmitChats(
    String userId,
    bool isAdmin,
    StreamController<List<ChatWithDetails>> controller,
  ) {
    if (controller.isClosed) return;

    getChats(userId, isAdmin)
        .then((chats) {
          if (!controller.isClosed) {
            controller.add(chats);
          }
        })
        .catchError((error) {
          if (!controller.isClosed) {
            controller.addError(error);
          }
        });
  }

  // Real-time stream for messages
  Stream<List<Message>> getMessagesStream(int chatId) {
    final streamKey = 'messages_$chatId';

    // Cancel existing stream
    _activeSubscriptions[streamKey]?.unsubscribe();
    _activeControllers[streamKey]?.close();

    final controller = StreamController<List<Message>>.broadcast();
    _activeControllers[streamKey] = controller;

    // Fetch initial messages
    _fetchAndEmitMessages(chatId, controller);

    // Set up real-time subscription for INSERT and UPDATE events
    final messagesChannel =
        _supabaseClient
            .channel('messages_$chatId')
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
                _fetchAndEmitMessages(chatId, controller);
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
                _fetchAndEmitMessages(chatId, controller);
              },
            )
            .subscribe();

    _activeSubscriptions[streamKey] = messagesChannel;

    // Clean up when stream is closed
    controller.onCancel = () {
      messagesChannel.unsubscribe();
      _activeSubscriptions.remove(streamKey);
      _activeControllers.remove(streamKey);
    };

    return controller.stream;
  }

  // Helper method to fetch and emit messages
  void _fetchAndEmitMessages(
    int chatId,
    StreamController<List<Message>> controller,
  ) {
    if (controller.isClosed) return;

    getChatMessages(chatId)
        .then((messages) {
          if (!controller.isClosed) {
            controller.add(messages);
          }
        })
        .catchError((error) {
          if (!controller.isClosed) {
            controller.addError(error);
          }
        });
  }

  // Find existing chat between two users
  Future<Chat?> findExistingChat(
    String userId,
    String otherUserId,
    bool isCurrentUserAdmin,
  ) async {
    try {
      if (!_isValidUUID(userId) || !_isValidUUID(otherUserId)) {
        throw Exception(
          'Invalid UUID format. userId: $userId, otherUserId: $otherUserId',
        );
      }

      PostgrestFilterBuilder query = _supabaseClient.from('chats').select();

      if (isCurrentUserAdmin) {
        query = query.eq('admin_id', userId).eq('customer_id', otherUserId);
      } else {
        query = query.eq('customer_id', userId).eq('admin_id', otherUserId);
      }

      final response = await query.maybeSingle();

      if (response != null) {
        final chat = Chat.fromJson(response);

        return chat;
      }

      return null;
    } catch (e) {
      throw Exception('Failed to find existing chat: $e');
    }
  }

  // Create new chat
  Future<Chat> createChat(String customerId, String adminId) async {
    try {
      if (!_isValidUUID(customerId) || !_isValidUUID(adminId)) {
        throw Exception(
          'Invalid UUID format. customerId: $customerId, adminId: $adminId',
        );
      }

      final response =
          await _supabaseClient
              .from('chats')
              .insert({
                'customer_id': customerId,
                'admin_id': adminId,
                'created_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      final chat = Chat.fromJson(response);

      return chat;
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  // Get messages for a chat
  Future<List<Message>> getChatMessages(int chatId) async {
    try {
      final response = await _supabaseClient
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);

      final messages =
          response.map<Message>((json) => Message.fromJson(json)).toList();

      return messages;
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  // Send message with proper validation
  Future<Message> sendMessage({
    required int chatId,
    required String senderId,
    required MessageSenderType senderType,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      if (!_isValidUUID(senderId)) {
        throw Exception('Invalid sender ID format: $senderId');
      }

      final now = DateTime.now();

      // Insert the message
      final messageResponse =
          await _supabaseClient
              .from('messages')
              .insert({
                'chat_id': chatId,
                'sender_id': senderId,
                'sender_type': senderType.name,
                'content': content,
                'message_type': messageType,
                'created_at': now.toIso8601String(),
                'is_read':
                    senderType ==
                    MessageSenderType
                        .admin, // Admin messages are read by default
              })
              .select()
              .single();

      // Determine the last message text based on message type
      String lastMessageText;
      switch (messageType.toLowerCase()) {
        case 'image':
          lastMessageText = '📷 Image';
          break;
        case 'pdf':
          lastMessageText = '📄 PDF Document';
          break;
        default:
          lastMessageText = content;
          break;
      }

      // Update chat's last message info
      await _supabaseClient
          .from('chats')
          .update({
            'last_message': lastMessageText,
            'last_message_at': now.toIso8601String(),
          })
          .eq('id', chatId);

      final message = Message.fromJson(messageResponse);
      return message;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(int chatId, String userId) async {
    try {
      if (!_isValidUUID(userId)) {
        return;
      }

      await _supabaseClient
          .from('messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('chat_id', chatId)
          .neq('sender_id', userId)
          .eq('is_read', false);
    } catch (e) {}
  }

  Future<Chat> getOrCreateChatForAppointment(String appointmentId) async {
    try {
      if (!_isValidUUID(appointmentId)) {
        throw Exception('Invalid appointment ID format: $appointmentId');
      }

      // Query appointments table with correct field names matching your database
      final appointmentResponse =
          await _supabaseClient
              .from('appointments')
              .select(
                'customer_id, workshop_id',
              ) // Using workshop_id instead of admin_id
              .eq('id', appointmentId)
              .maybeSingle();

      if (appointmentResponse == null) {
        throw Exception('Appointment not found with ID: $appointmentId');
      }

      final customerId = appointmentResponse['customer_id'] as String?;
      final workshopId =
          appointmentResponse['workshop_id'] as String?; // This is the admin ID

      if (customerId == null || workshopId == null) {
        throw Exception(
          'Missing required data in appointment. customerId: $customerId, workshopId: $workshopId',
        );
      }

      // The workshop_id from appointments table corresponds to the admin_id in chats table
      return await _getOrCreateChatBetweenUsers(customerId, workshopId);
    } catch (e) {
      if (e.toString().contains('PGRST116')) {
        throw Exception(
          'Appointment not found or invalid appointment ID: $appointmentId',
        );
      }

      throw Exception('Failed to get or create chat for appointment: $e');
    }
  }

  // Helper method to get or create chat between users
  Future<Chat> _getOrCreateChatBetweenUsers(
    String customerId,
    String adminId,
  ) async {
    if (!_isValidUUID(customerId) || !_isValidUUID(adminId)) {
      throw Exception(
        'Invalid UUID format. customerId: $customerId, adminId: $adminId',
      );
    }

    // Check if chat already exists between customer and admin
    final existingChat = await findExistingChat(customerId, adminId, false);

    if (existingChat != null) {
      return existingChat;
    }

    return await createChat(customerId, adminId);
  }

  // Add method to get or create chat between specific users (public method)
  Future<Chat> getOrCreateChatBetweenUsers({
    required String currentUserId,
    required String otherUserId,
    required bool isCurrentUserAdmin,
  }) async {
    try {
      if (!_isValidUUID(currentUserId) || !_isValidUUID(otherUserId)) {
        throw Exception(
          'Invalid UUID format. currentUserId: $currentUserId, otherUserId: $otherUserId',
        );
      }

      // Check if chat already exists
      final existingChat = await findExistingChat(
        currentUserId,
        otherUserId,
        isCurrentUserAdmin,
      );

      if (existingChat != null) {
        return existingChat;
      }

      // Determine which user is customer and which is admin
      String customerId, adminId;

      if (isCurrentUserAdmin) {
        adminId = currentUserId;
        customerId = otherUserId;
      } else {
        customerId = currentUserId;
        adminId = otherUserId;
      }

      return await createChat(customerId, adminId);
    } catch (e) {
      throw Exception('Failed to get or create chat between users: $e');
    }
  }

  // DEPRECATED: Use getChatsStream instead
  Stream<List<ChatWithDetails>> watchChats(String userId, bool isAdmin) {
    return getChatsStream(userId, isAdmin);
  }

  // DEPRECATED: Use getMessagesStream instead
  Stream<List<Message>> watchChatMessages(int chatId) {
    return getMessagesStream(chatId);
  }

  // Clean up all subscriptions
  void dispose() {
    for (final controller in _activeControllers.values) {
      controller.close();
    }
    _activeControllers.clear();

    for (final subscription in _activeSubscriptions.values) {
      subscription.unsubscribe();
    }
    _activeSubscriptions.clear();
  }

  // Helper method to validate UUID format
  bool _isValidUUID(String uuid) {
    if (uuid.isEmpty) return false;
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(uuid);
  }
}
