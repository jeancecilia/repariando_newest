enum MessageSenderType { customer, admin }

class Message {
  final int id;
  final DateTime createdAt;
  final int chatId;
  final MessageSenderType senderType;
  final String senderId;
  final String messageType;
  final String? content;
  final bool isRead;
  final DateTime? readAt;

  const Message({
    required this.id,
    required this.createdAt,
    required this.chatId,
    required this.senderType,
    required this.senderId,
    required this.messageType,
    this.content,
    required this.isRead,
    this.readAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at'] as String),
      chatId: json['chat_id'],
      senderType: MessageSenderType.values.firstWhere(
        (e) => e.name == json['sender_type'],
        orElse: () => MessageSenderType.customer,
      ),
      senderId: json['sender_id'] as String,
      messageType: json['message_type'] as String,
      content: json['content'] ?? '',
      isRead: json['is_read'] as bool,
      readAt:
          json['read_at'] != null
              ? DateTime.parse(json['read_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'chat_id': chatId,
      'sender_type': senderType.name,
      'sender_id': senderId,
      'message_type': messageType,
      'content': content,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
    };
  }

  Message copyWith({
    int? id,
    DateTime? createdAt,
    int? chatId,
    MessageSenderType? senderType,
    String? senderId,
    String? messageType,
    String? content,
    bool? isRead,
    DateTime? readAt,
  }) {
    return Message(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      chatId: chatId ?? this.chatId,
      senderType: senderType ?? this.senderType,
      senderId: senderId ?? this.senderId,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }

  bool get isFromUser => senderType == MessageSenderType.customer;
}
