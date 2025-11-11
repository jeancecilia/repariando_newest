import 'package:repairando_mobile/src/features/messages/domain/chat_model.dart';

class ChatWithDetails {
  final Chat chat;
  final String? otherUserName;
  final String? otherUserImage;
  final int unreadCount;

  const ChatWithDetails({
    required this.chat,
    this.otherUserName,
    this.otherUserImage,
    this.unreadCount = 0,
  });

  factory ChatWithDetails.fromJson(Map<String, dynamic> json) {
    return ChatWithDetails(
      chat: Chat.fromJson(json),
      otherUserName: json['other_user_name'] as String?,
      otherUserImage: json['other_user_image'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...chat.toJson(),
      'other_user_name': otherUserName,
      'other_user_image': otherUserImage,
      'unread_count': unreadCount,
    };
  }
}
