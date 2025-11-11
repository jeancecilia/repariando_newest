// Updated WorkshopMessagesScreen - Real-time Messaging UI with Image Support (Localized)
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:repairando_mobile/src/constants/app_images.dart';
import 'package:repairando_mobile/src/features/messages/presentation/controllers/chat_controller.dart';
import 'package:repairando_mobile/src/features/messages/domain/message_model.dart';
import 'package:repairando_mobile/src/common/widgets/circle_back_button.dart';
import 'package:repairando_mobile/src/theme/theme.dart';
import 'package:repairando_mobile/src/router/app_router.dart';
import 'package:go_router/go_router.dart';

class WorkshopMessagesScreen extends HookConsumerWidget {
  final int chatId;
  final String chatName;
  final String? otherUserImage;

  const WorkshopMessagesScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    this.otherUserImage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final scrollController = useScrollController();
    final messageState = ref.watch(messageControllerProvider(chatId));
    final currentUser = ref.watch(currentUserProvider);
    final isAdminAsync = ref.watch(isAdminProvider);
    final imagePicker = useMemoized(() => ImagePicker());

    // Keep track of previous message count for auto-scroll
    final previousMessageCount = useRef(0);

    // Auto-scroll to bottom when new messages arrive
    useEffect(() {
      if (messageState.messages.isNotEmpty &&
          messageState.messages.length > previousMessageCount.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
      previousMessageCount.value = messageState.messages.length;
      return null;
    }, [messageState.messages.length]);

    // Mark messages as read when entering the chat or when new messages arrive
    useEffect(() {
      if (currentUser != null && messageState.messages.isNotEmpty) {
        // Small delay to ensure messages are rendered
        Future.delayed(const Duration(milliseconds: 500), () {
          ref
              .read(messageControllerProvider(chatId).notifier)
              .markMessagesAsRead(currentUser.id);
        });
      }
      return null;
    }, [chatId, currentUser?.id, messageState.messages.length]);

    // Focus and scroll to bottom when screen is opened
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients && messageState.messages.isNotEmpty) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      });
      return null;
    }, []);

    return Scaffold(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      appBar: AppBar(
        backgroundColor: AppTheme.BACKGROUND_COLOR,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleBackButton(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.PRIMARY_COLOR,
              backgroundImage:
                  otherUserImage != null ? NetworkImage(otherUserImage!) : null,
              child:
                  otherUserImage == null
                      ? isAdminAsync.when(
                        data:
                            (isCurrentUserAdmin) => Icon(
                              isCurrentUserAdmin ? Icons.person : Icons.build,
                              color: Colors.white,
                              size: 18,
                            ),
                        loading:
                            () => Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 18,
                            ),
                        error:
                            (_, __) => Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 18,
                            ),
                      )
                      : null,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatName,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.TEXT_COLOR,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Retry button if not connected
          if (!messageState.isConnected)
            IconButton(
              icon: Icon(Icons.refresh, color: AppTheme.PRIMARY_COLOR),
              onPressed: () {
                ref
                    .read(messageControllerProvider(chatId).notifier)
                    .retryConnection();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                messageState.isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppTheme.PRIMARY_COLOR,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'loading_messages'.tr(),
                            style: GoogleFonts.manrope(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                    : messageState.error != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'error_loading_messages'.tr(),
                            style: GoogleFonts.manrope(color: Colors.red),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            messageState.error!,
                            style: GoogleFonts.manrope(
                              color: Colors.grey[600],
                              fontSize: 12,
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
                                      .read(
                                        messageControllerProvider(
                                          chatId,
                                        ).notifier,
                                      )
                                      .retryConnection();
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
                                      .read(
                                        messageControllerProvider(
                                          chatId,
                                        ).notifier,
                                      )
                                      .clearError();
                                },
                                child: Text('dismiss'.tr()),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                    : messageState.messages.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'no_messages_yet'.tr(),
                            style: GoogleFonts.manrope(color: Colors.grey[600]),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'start_conversation'.tr(),
                            style: GoogleFonts.manrope(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: messageState.messages.length,
                      itemBuilder: (context, index) {
                        final message = messageState.messages[index];
                        final isCurrentUser =
                            message.senderId == currentUser?.id;

                        // Show date separator if needed
                        bool showDateSeparator = false;
                        if (index == 0) {
                          showDateSeparator = true;
                        } else {
                          final previousMessage =
                              messageState.messages[index - 1];
                          final currentDate = DateTime(
                            message.createdAt.year,
                            message.createdAt.month,
                            message.createdAt.day,
                          );
                          final previousDate = DateTime(
                            previousMessage.createdAt.year,
                            previousMessage.createdAt.month,
                            previousMessage.createdAt.day,
                          );
                          showDateSeparator =
                              !currentDate.isAtSameMomentAs(previousDate);
                        }

                        return Column(
                          children: [
                            if (showDateSeparator)
                              DateSeparator(date: message.createdAt),
                            MessageBubble(
                              message: message,
                              isCurrentUser: isCurrentUser,
                              otherUserImage: otherUserImage,
                              showAvatar: _shouldShowAvatar(
                                messageState.messages,
                                index,
                                isCurrentUser,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SafeArea(
              child: Row(
                children: [
                  // Text Field with attachment icons inside
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          // Image icon
                          IconButton(
                            icon: Image.asset(
                              AppImages.GALLERY_IMAGE,
                              height: 24,
                            ),
                            onPressed:
                                () => _pickAndSendImage(
                                  ref,
                                  imagePicker,
                                  context,
                                  currentUser,
                                  isAdminAsync,
                                ),
                          ),

                          // PDF icon
                          IconButton(
                            icon: Icon(
                              Icons.picture_as_pdf,
                              color: AppTheme.PRIMARY_COLOR,
                              size: 24,
                            ),
                            onPressed:
                                () => _pickAndSendPdf(
                                  ref,
                                  context,
                                  currentUser,
                                  isAdminAsync,
                                ),
                          ),

                          // Text input
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              style: GoogleFonts.manrope(
                                color: AppTheme.TEXT_COLOR,
                              ),
                              maxLines: 4,
                              minLines: 1,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'type_your_message'.tr(),
                                hintStyle: const TextStyle(
                                  color: Color(0xFF8E8E93),
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 5,
                                ),
                              ),
                              onSubmitted:
                                  (value) => _sendMessage(
                                    ref,
                                    messageController,
                                    currentUser,
                                    isAdminAsync,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send Button
                  GestureDetector(
                    onTap:
                        messageState.isSending
                            ? null
                            : () => _sendMessage(
                              ref,
                              messageController,
                              currentUser,
                              isAdminAsync,
                            ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          messageState.isSending
                              ? Colors.grey[300]
                              : AppTheme.PRIMARY_COLOR,
                      child:
                          messageState.isSending
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowAvatar(
    List<Message> messages,
    int index,
    bool isCurrentUser,
  ) {
    // Always show avatar for the last message
    if (index == messages.length - 1) return true;

    // Show avatar if next message is from different sender
    final nextMessage = messages[index + 1];
    return nextMessage.senderId != messages[index].senderId;
  }

  void _sendMessage(
    WidgetRef ref,
    TextEditingController controller,
    currentUser,
    AsyncValue<bool> isAdminAsync,
  ) {
    final message = controller.text.trim();
    if (message.isEmpty || currentUser == null) return;

    final isAdmin = isAdminAsync.when(
      data: (value) => value,
      loading: () => false,
      error: (_, __) => false,
    );

    ref
        .read(messageControllerProvider(chatId).notifier)
        .sendMessage(
          senderId: currentUser.id,
          senderType:
              isAdmin ? MessageSenderType.admin : MessageSenderType.customer,
          content: message,
        );

    controller.clear();
  }

  Future<void> _pickAndSendImage(
    WidgetRef ref,
    ImagePicker imagePicker,
    BuildContext context,
    currentUser,
    AsyncValue<bool> isAdminAsync,
  ) async {
    if (currentUser == null) return;

    try {
      // Show image source selection dialog
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder:
            (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'select_image_source'.tr(),
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.TEXT_COLOR,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.camera_alt,
                      color: AppTheme.PRIMARY_COLOR,
                    ),
                    title: Text(
                      'camera'.tr(),
                      style: GoogleFonts.manrope(color: AppTheme.TEXT_COLOR),
                    ),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.photo_library,
                      color: AppTheme.PRIMARY_COLOR,
                    ),
                    title: Text(
                      'gallery'.tr(),
                      style: GoogleFonts.manrope(color: AppTheme.TEXT_COLOR),
                    ),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
      );

      if (source == null) return;

      final XFile? pickedFile = await imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      final isAdmin = isAdminAsync.when(
        data: (value) => value,
        loading: () => false,
        error: (_, __) => false,
      );

      // Send image message
      await ref
          .read(messageControllerProvider(chatId).notifier)
          .sendImageMessage(
            senderId: currentUser.id,
            senderType:
                isAdmin ? MessageSenderType.admin : MessageSenderType.customer,
            imagePath: pickedFile.path,
          );
    } catch (e) {
      // Show error snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'failed_to_send_image'.tr(namedArgs: {'error': e.toString()}),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickAndSendPdf(
    WidgetRef ref,
    BuildContext context,
    currentUser,
    AsyncValue<bool> isAdminAsync,
  ) async {
    print('🔍 PDF Picker Debug - Starting...');
    print('👤 Current user: ${currentUser?.id}');

    if (currentUser == null) {
      print('❌ No current user, returning');
      return;
    }

    try {
      print('📁 Opening file picker...');
      // Pick PDF file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      print('📋 File picker result: ${result != null ? 'File selected' : 'No file selected'}');

      if (result != null && result.files.single.path != null) {
        final file = result.files.first;
        final fileName = file.name;
        final filePath = file.path!;

        print('📄 Selected file details:');
        print('📄 File name: $fileName');
        print('📄 File path: $filePath');
        print('📄 File size: ${file.size} bytes');

        final isAdmin = isAdminAsync.when(
          data: (value) => value,
          loading: () => false,
          error: (_, __) => false,
        );

        print('👤 Is admin: $isAdmin');
        print('📤 Calling sendPdfMessage...');

        // Send PDF message
        await ref
            .read(messageControllerProvider(chatId).notifier)
            .sendPdfMessage(
              senderId: currentUser.id,
              senderType:
                  isAdmin ? MessageSenderType.admin : MessageSenderType.customer,
              pdfPath: filePath,
              fileName: fileName,
            );

        print('✅ PDF picker completed successfully!');
      } else {
        print('ℹ️ No file selected or file path is null');
      }
    } catch (e) {
      print('❌ Error in PDF picker:');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error message: ${e.toString()}');

      // Show error snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'failed_to_send_pdf'.tr(namedArgs: {'error': e.toString()}),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

// Date separator widget
class DateSeparator extends StatelessWidget {
  final DateTime date;

  const DateSeparator({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDate(date),
              style: GoogleFonts.manrope(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'today'.tr();
    } else if (messageDate == yesterday) {
      return 'yesterday'.tr();
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}

// Enhanced message bubble with image support
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final String? otherUserImage;
  final bool showAvatar;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.otherUserImage,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            showAvatar
                ? CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.PRIMARY_COLOR,
                  backgroundImage:
                      otherUserImage != null
                          ? NetworkImage(otherUserImage!)
                          : null,
                  child:
                      otherUserImage == null
                          ? Icon(
                            message.senderType == MessageSenderType.admin
                                ? Icons.build
                                : Icons.person,
                            color: Colors.white,
                            size: 18,
                          )
                          : null,
                )
                : const SizedBox(width: 32), // Placeholder for alignment
            const SizedBox(width: 8),
          ],
          if (isCurrentUser) SizedBox(width: 40.w),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.all(message.messageType == 'image' ? 4 : 16),
              decoration: BoxDecoration(
                color:
                    isCurrentUser ? AppTheme.PRIMARY_COLOR : Color(0xFFECEFF4),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(isCurrentUser ? 20 : 6),
                  bottomRight: Radius.circular(isCurrentUser ? 6 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Normalize message type for comparison (case-insensitive and trim whitespace)
                  Builder(
                    builder: (context) {
                      final normalizedMessageType = message.messageType.trim().toLowerCase();

                      // Debug: Log message type for troubleshooting
                      print('📨 Message Type Debug:');
                      print('   Original: "${message.messageType}"');
                      print('   Normalized: "$normalizedMessageType"');
                      print('   Content preview: ${(message.content ?? "").substring(0, (message.content?.length ?? 0) > 50 ? 50 : (message.content?.length ?? 0))}...');

                      if (normalizedMessageType == 'image') {
                        return _buildImageContent(context);
                      } else if (normalizedMessageType == 'pdf') {
                        return _buildPdfContent(context);
                      } else {
                        return Text(
                          message.content ?? '',
                          style: GoogleFonts.manrope(
                            color:
                                isCurrentUser ? Colors.white : AppTheme.TEXT_COLOR,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.createdAt),
                        style: GoogleFonts.manrope(
                          color:
                              isCurrentUser
                                  ? Colors.white.withOpacity(0.7)
                                  : Color(0xFF8E8E93),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!isCurrentUser) SizedBox(width: 40.w),
        ],
      ),
    );
  }

  Widget _buildImageContent(context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () => _showFullScreenImage(context),
        child: Image.network(
          message.content ?? '',
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[300],
              child: Center(
                child: CircularProgressIndicator(
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                  color: AppTheme.PRIMARY_COLOR,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[300],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.grey[600], size: 40),
                  SizedBox(height: 8),
                  Text(
                    'failed_to_load_image'.tr(),
                    style: GoogleFonts.manrope(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPdfContent(BuildContext context) {
    return GestureDetector(
      onTap: () => _openPdf(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? Colors.white.withOpacity(0.2)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrentUser
                ? Colors.white.withOpacity(0.3)
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.picture_as_pdf,
              color: isCurrentUser ? Colors.white : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PDF Document',
                    style: GoogleFonts.manrope(
                      color: isCurrentUser ? Colors.white : AppTheme.TEXT_COLOR,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to view',
                    style: GoogleFonts.manrope(
                      color: isCurrentUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: isCurrentUser
                  ? Colors.white.withOpacity(0.7)
                  : Colors.grey[600],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _openPdf(BuildContext context) async {
    try {
      // Extract filename from URL or use default
      String fileName = 'PDF Document';
      try {
        final uri = Uri.parse(message.content!);
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          fileName = pathSegments.last;
          // Remove query parameters if any
          if (fileName.contains('?')) {
            fileName = fileName.split('?').first;
          }
        }
      } catch (e) {
        print('Error parsing filename from URL: $e');
      }

      // Navigate to PDF viewer screen
      if (context.mounted) {
        print('Navigating to PDF viewer screen');
        print('PDF URL: ${message.content}');
        context.push(
          AppRoutes.pdfViewer,
          extra: {
            'pdfUrl': message.content!,
            'fileName': fileName,
          },
        );
      }
    } catch (e) {
      print('Error opening PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_opening_pdf'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFullScreenImage(context) {
    // You can implement full-screen image viewer here
    // For now, we'll just show a basic dialog
    showDialog(
      context: context, // You'll need to pass context here
      builder:
          (context) => Dialog(
            backgroundColor: Colors.black,
            child: InteractiveViewer(
              child: Image.network(message.content!, fit: BoxFit.contain),
            ),
          ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat('EEE HH:mm').format(dateTime);
    } else {
      return DateFormat('MMM d, HH:mm').format(dateTime);
    }
  }
}
