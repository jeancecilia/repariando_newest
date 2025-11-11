class Chat {
  final int id;
  final DateTime createdAt;
  final String? adminId;
  final String customerId;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const Chat({
    required this.id,
    required this.createdAt,
    this.adminId,
    required this.customerId,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at'] as String),
      adminId: json['admin_id'] as String?,
      customerId: json['customer_id'] as String,
      lastMessage: json['last_message'] as String?,
      lastMessageAt:
          json['last_message_at'] != null
              ? DateTime.parse(json['last_message_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'admin_id': adminId,
      'customer_id': customerId,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
    };
  }

  Chat copyWith({
    int? id,
    DateTime? createdAt,
    String? adminId,
    String? customerId,
    String? lastMessage,
    DateTime? lastMessageAt,
  }) {
    return Chat(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      adminId: adminId ?? this.adminId,
      customerId: customerId ?? this.customerId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}
