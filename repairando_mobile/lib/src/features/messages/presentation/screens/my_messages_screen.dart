// Updated MyMessagesScreen - my_messages_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/common/widgets/circle_back_button.dart';
import 'package:repairando_mobile/src/constants/app_images.dart';
import 'package:repairando_mobile/src/features/messages/presentation/controllers/chat_controller.dart';
import 'package:repairando_mobile/src/router/app_router.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class MyMessagesScreen extends HookConsumerWidget {
  final bool backButton;

  const MyMessagesScreen({super.key, required this.backButton});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatControllerProvider);
    final isAdminAsync = ref.watch(isAdminProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: backButton,
        automaticallyImplyLeading: false,
        leading:
            backButton
                ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleBackButton(),
                )
                : null,
        title: Text(
          'messages_screen_title'.tr(),
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.TEXT_COLOR,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              context.push(AppRoutes.notification);
            },
            child: Image.asset(AppImages.NOTIFICATION_ICON, height: 30.h),
          ),
          SizedBox(width: 10.w),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),
            if (chatState.isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'loading_chats'.tr(),
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else if (chatState.error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16.h),
                      Text(
                        'error_loading_chats'.tr(),
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        chatState.error!,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(chatControllerProvider.notifier)
                                  .fetchChats();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.PRIMARY_COLOR,
                            ),
                            child: Text('retry'.tr()),
                          ),
                          SizedBox(width: 8.w),
                          OutlinedButton(
                            onPressed: () {
                              ref
                                  .read(chatControllerProvider.notifier)
                                  .clearError();
                            },
                            child: Text('dismiss'.tr()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else if (chatState.chats.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'no_messages_yet'.tr(),
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'conversations_appear_here'.tr(),
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(chatControllerProvider.notifier)
                        .fetchChats();
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: chatState.chats.length,
                    itemBuilder: (context, index) {
                      final chatDetails = chatState.chats[index];
                      final chat = chatDetails.chat;

                      return GestureDetector(
                        onTap: () {
                          context.push(
                            AppRoutes.workshopMessages,
                            extra: {
                              'chatId': chat.id,
                              'chatName':
                                  chatDetails.otherUserName ??
                                  'chat_default_name'.tr(),
                              'otherUserImage': chatDetails.otherUserImage,
                            },
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          decoration: BoxDecoration(
                            color: AppTheme.LITE_PRIMARY_COLOR,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                // Avatar with status indicator
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppTheme.PRIMARY_COLOR,
                                      backgroundImage:
                                          chatDetails.otherUserImage != null
                                              ? NetworkImage(
                                                chatDetails.otherUserImage!,
                                              )
                                              : null,
                                      child:
                                          chatDetails.otherUserImage == null
                                              ? isAdminAsync.when(
                                                data: (isCurrentUserAdmin) {
                                                  // Show icon based on who the OTHER user is
                                                  return Icon(
                                                    isCurrentUserAdmin
                                                        ? Icons
                                                            .person // If current user is admin, other is customer
                                                        : Icons
                                                            .build, // If current user is customer, other is admin
                                                    color: Colors.white,
                                                    size: 24,
                                                  );
                                                },
                                                loading:
                                                    () => Icon(
                                                      Icons.person,
                                                      color: Colors.white,
                                                      size: 24,
                                                    ),
                                                error:
                                                    (_, __) => Icon(
                                                      Icons.person,
                                                      color: Colors.white,
                                                      size: 24,
                                                    ),
                                              )
                                              : null,
                                    ),
                                  ],
                                ),
                                SizedBox(width: 16.w),

                                // Chat details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Name and user type
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              chatDetails.otherUserName!,
                                              style: GoogleFonts.manrope(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.TEXT_COLOR,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),

                                      if (chat.lastMessage != null) ...[
                                        SizedBox(height: 6.h),

                                        Text(
                                          chat.lastMessage!,
                                          style: GoogleFonts.manrope(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.TEXT_COLOR
                                                .withOpacity(0.7),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ] else ...[
                                        SizedBox(height: 6.h),
                                        Text(
                                          'no_messages_yet_chat'.tr(),
                                          style: GoogleFonts.manrope(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey[500],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                SizedBox(width: 12.w),

                                // Time and unread indicator
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (chat.lastMessageAt != null)
                                      Text(
                                        _formatTime(chat.lastMessageAt!),
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.TEXT_COLOR
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Today - show time
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'yesterday'.tr();
    } else if (difference.inDays < 7) {
      // This week - show day
      return DateFormat('EEE').format(dateTime);
    } else if (difference.inDays < 365) {
      // This year - show month and day
      return DateFormat('MMM d').format(dateTime);
    } else {
      // Older - show year
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }
}
