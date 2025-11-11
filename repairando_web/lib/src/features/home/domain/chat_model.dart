class Chat {
  final int id;
  final String customerId;
  final String? adminId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final String? customerName;
  final String? customerEmail;
  final int unreadCount;

  Chat({
    required this.id,
    required this.customerId,
    this.adminId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    this.customerName,
    this.customerEmail,
    this.unreadCount = 0,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    // Handle nested customer data from JOIN queries
    final customerData = json['customers'] as Map<String, dynamic>?;

    return Chat(
      id: json['id'] as int,
      customerId: json['customer_id'] as String? ?? '',
      adminId: json['admin_id'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt:
          json['last_message_at'] != null
              ? DateTime.tryParse(json['last_message_at'] as String)
              : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      customerName: customerData?['name'] as String? ?? 'Unknown User',
      customerEmail: customerData?['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'admin_id': adminId,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Chat copyWith({
    int? id,
    String? customerId,
    String? adminId,
    String? lastMessage,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    String? customerName,
    String? customerEmail,
    int? unreadCount,
  }) {
    return Chat(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      adminId: adminId ?? this.adminId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  // Helper method to get display name
  String get displayName =>
      customerName?.isNotEmpty == true ? customerName! : 'Unknown User';

  // Helper method to get initials for avatar
  String get initials {
    if (customerName?.isNotEmpty == true) {
      final names = customerName!.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      }
      return customerName![0].toUpperCase();
    }
    return 'U';
  }

  // Helper method to check if chat has recent activity
  bool get hasRecentActivity {
    if (lastMessageAt == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastMessageAt!);
    return difference.inDays < 7;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat &&
        other.id == id &&
        other.customerId == customerId &&
        other.adminId == adminId &&
        other.lastMessage == lastMessage &&
        other.lastMessageAt == lastMessageAt &&
        other.createdAt == createdAt &&
        other.customerName == customerName &&
        other.customerEmail == customerEmail &&
        other.unreadCount == unreadCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      customerId,
      adminId,
      lastMessage,
      lastMessageAt,
      createdAt,
      customerName,
      customerEmail,
      unreadCount,
    );
  }

  @override
  String toString() {
    return 'Chat(id: $id, customerId: $customerId, customerName: $customerName, unreadCount: $unreadCount)';
  }
}

class Message {
  final int id;
  final int chatId;
  final String senderId;
  final String senderType;
  final String messageType;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderType,
    required this.messageType,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int,
      chatId: json['chat_id'] as int,
      senderId: json['sender_id'] as String? ?? '',
      senderType: json['sender_type'] as String? ?? '',
      messageType: json['message_type'] as String? ?? 'text',
      content: json['content'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt:
          json['read_at'] != null
              ? DateTime.tryParse(json['read_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'sender_type': senderType,
      'message_type': messageType,
      'content': content,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  Message copyWith({
    int? id,
    int? chatId,
    String? senderId,
    String? senderType,
    String? messageType,
    String? content,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  // Helper method to check if message is from admin
  bool get isFromAdmin => senderType.toLowerCase() == 'admin';

  // Helper method to check if message is from customer
  bool get isFromCustomer => senderType.toLowerCase() == 'customer';

  // Helper method to get formatted time
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      final hour = createdAt.hour;
      final minute = createdAt.minute.toString().padLeft(2, '0');
      final amPm = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$displayHour:$minute $amPm';
    } else if (difference.inDays < 7) {
      final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return weekdays[createdAt.weekday % 7];
    } else {
      final month = createdAt.month.toString().padLeft(2, '0');
      final day = createdAt.day.toString().padLeft(2, '0');
      return '$month/$day';
    }
  }

  // Helper method to check if message should show timestamp
  bool shouldShowTimestamp(Message? previousMessage) {
    if (previousMessage == null) return true;

    final timeDifference = createdAt.difference(previousMessage.createdAt);
    return timeDifference.inMinutes >= 5;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id &&
        other.chatId == chatId &&
        other.senderId == senderId &&
        other.senderType == senderType &&
        other.messageType == messageType &&
        other.content == content &&
        other.isRead == isRead &&
        other.createdAt == createdAt &&
        other.readAt == readAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      chatId,
      senderId,
      senderType,
      messageType,
      content,
      isRead,
      createdAt,
      readAt,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, chatId: $chatId, senderType: $senderType, content: ${content.substring(0, content.length > 20 ? 20 : content.length)}...)';
  }
}

// Enum for message types
enum MessageType {
  text,
  image,
  file,
  voice,
  video;

  String get value => name;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.text,
    );
  }
}

// Enum for sender types
enum SenderType {
  admin,
  customer;

  String get value => name;

  static SenderType fromString(String value) {
    return SenderType.values.firstWhere(
      (type) => type.value == value.toLowerCase(),
      orElse: () => SenderType.customer,
    );
  }
}
