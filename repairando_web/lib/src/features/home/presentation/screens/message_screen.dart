import 'package:flutter/material.dart';
import 'package:repairando_web/src/features/home/domain/chat_model.dart';
import 'package:repairando_web/src/features/home/presentation/controllers/chat_controller.dart';
import 'package:repairando_web/src/features/home/presentation/screens/base_layout.dart';
import 'package:repairando_web/src/router/app_router.dart';
import 'package:repairando_web/src/theme/theme.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:repairando_web/src/widgets/pdf_viewer_dialog.dart';

class MessagesScreen extends HookConsumerWidget {
  final String? initialChatId; // Add this parameter

  const MessagesScreen({super.key, this.initialChatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final messageText = useState('');
    final selectedChatId = useState<int?>(null);
    final selectedChat = useState<Chat?>(null);
    final currentAdminId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final isUploadingImage = useState(false);
    final isUploadingPdf = useState(false);
    final hasInitialized = useState(false); // Track if we've initialized

    // Listen to chats stream with customer names
    final chatsAsync = ref.watch(chatsStreamProvider);

    // Listen to messages stream for selected chat
    final messagesAsync =
        selectedChatId.value != null
            ? ref.watch(messagesStreamProvider(selectedChatId.value!))
            : const AsyncValue<List<Message>>.data([]);

    // Create scroll controller for auto-scrolling
    final scrollController = useScrollController();

    // Handle initial chat ID from URL parameter
    useEffect(() {
      if (initialChatId != null && !hasInitialized.value) {
        final chatId = int.tryParse(initialChatId!);
        if (chatId != null) {
          chatsAsync.whenData((chats) {
            // Find the chat with the matching ID
            final targetChat = chats.firstWhere((chat) => chat.id == chatId);

            selectedChatId.value = chatId;
            selectedChat.value = targetChat;
            hasInitialized.value = true;
          });
        }
      }
      return null;
    }, [initialChatId, chatsAsync.value]);

    useEffect(() {
      void listener() {
        messageText.value = messageController.text;
      }

      messageController.addListener(listener);
      return () => messageController.removeListener(listener);
    }, [messageController]);

    // Auto-scroll to bottom when new messages arrive
    useEffect(() {
      if (messagesAsync.hasValue && messagesAsync.value!.isNotEmpty) {
        // Use a slight delay to ensure the ListView has been built
        Future.delayed(const Duration(milliseconds: 100), () {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
      return null;
    }, [messagesAsync.value?.length]);

    // Mark messages as read when chat is selected
    useEffect(() {
      if (selectedChatId.value != null && currentAdminId.isNotEmpty) {
        // Delay to ensure the chat is fully loaded
        Future.delayed(const Duration(milliseconds: 500), () {
          ref
              .read(messagesControllerProvider.notifier)
              .markMessagesAsRead(selectedChatId.value!, currentAdminId);
        });
      }
      return null;
    }, [selectedChatId.value]);

    // Function to send message
    Future<void> sendMessage() async {
      final message = messageController.text.trim();
      if (message.isEmpty || selectedChatId.value == null) return;

      try {
        await ref
            .read(messagesControllerProvider.notifier)
            .sendMessage(
              chatId: selectedChatId.value!,
              senderId: currentAdminId,
              senderType: 'admin',
              content: message,
            );

        messageController.clear();

        // Scroll to bottom after sending message
        Future.delayed(const Duration(milliseconds: 200), () {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'failed_to_send_message'.tr(namedArgs: {'error': e.toString()}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Function to pick and send image
    Future<void> pickAndSendImage() async {
      if (selectedChatId.value == null) return;

      try {
        isUploadingImage.value = true;

        // Pick image file
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.single.bytes != null) {
          final file = result.files.single;
          final imageBytes = file.bytes!;
          final fileName = file.name;

          // Send image message
          await ref
              .read(messagesControllerProvider.notifier)
              .sendImageMessage(
                chatId: selectedChatId.value!,
                senderId: currentAdminId,
                senderType: 'admin',
                imageBytes: imageBytes,
                fileName: fileName,
              );

          // Scroll to bottom after sending image
          Future.delayed(const Duration(milliseconds: 200), () {
            if (scrollController.hasClients) {
              scrollController.animateTo(
                scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('image_sent_successfully'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'failed_to_send_image'.tr(namedArgs: {'error': e.toString()}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        isUploadingImage.value = false;
      }
    }

    // Function to pick and send PDF
    Future<void> pickAndSendPdf() async {
      if (selectedChatId.value == null) return;

      try {
        isUploadingPdf.value = true;

        // Pick PDF file
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          allowMultiple: false,
        );

        if (result != null && result.files.single.bytes != null) {
          final file = result.files.single;
          final pdfBytes = file.bytes!;
          final fileName = file.name;

          // Validate file extension
          if (!fileName.toLowerCase().endsWith('.pdf')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('pdf_files_only'.tr()),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          // Send PDF message
          await ref
              .read(messagesControllerProvider.notifier)
              .sendPdfMessage(
                chatId: selectedChatId.value!,
                senderId: currentAdminId,
                senderType: 'admin',
                pdfBytes: pdfBytes,
                fileName: fileName,
              );

          // Scroll to bottom after sending PDF
          Future.delayed(const Duration(milliseconds: 200), () {
            if (scrollController.hasClients) {
              scrollController.animateTo(
                scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('pdf_sent_successfully'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'failed_to_send_pdf'.tr(namedArgs: {'error': e.toString()}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        isUploadingPdf.value = false;
      }
    }

    // Function to show image in full screen
    void showImageDialog(String imageUrl) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Function to show PDF in dialog
    void showPdfDialog(String pdfUrl, String fileName) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return PdfViewerDialog(
            pdfUrl: pdfUrl,
            fileName: fileName,
          );
        },
      );
    }

    // Function to build message content based on type
    Widget _buildMessageContent(Message message, bool isAdmin) {
      // Normalize message type for comparison (case-insensitive and trim whitespace)
      final normalizedMessageType = message.messageType.trim().toLowerCase();

      // Debug: Log message type for troubleshooting
      print('📨 Message Type Debug:');
      print('   Original: "${message.messageType}"');
      print('   Normalized: "$normalizedMessageType"');
      print('   Content preview: ${message.content.substring(0, message.content.length > 50 ? 50 : message.content.length)}...');

      if (normalizedMessageType == 'image') {
        return GestureDetector(
          onTap: () => showImageDialog(message.content),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 200,
                maxHeight: 200,
              ),
              child: Image.network(
                message.content,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Colors.grey[600],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'image_failed_to_load'.tr(),
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
          ),
        );
      } else if (normalizedMessageType == 'pdf') {
        return GestureDetector(
          onTap: () => showPdfDialog(message.content, 'PDF Document'),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAdmin ? Colors.orange[400] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // PDF Icon Container
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAdmin ? Colors.orange[300] : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        color: isAdmin ? Colors.white : Colors.red[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.open_in_new,
                        color: isAdmin ? Colors.white : Colors.grey[600],
                        size: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Text Content
             Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'pdf_document'.tr(),
                        style: GoogleFonts.manrope(
                          color: isAdmin ? Colors.white : Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'tap_to_view_pdf'.tr(),
                        style: GoogleFonts.manrope(
                          color: isAdmin ? Colors.white70 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

              ],
            ),
          ),
        );
      } else {
        // Text message
        return Text(
          message.content,
          style: GoogleFonts.manrope(
            color: isAdmin ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        );
      }
    }

    return BaseLayout(
      title: 'messages'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'chat_title'.tr(),
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: AppTheme.BORDER_COLOR),

          // Main Content
          Expanded(
            child: Row(
              children: [
                // Chat List Sidebar
                Container(
                  width: 320,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      right: BorderSide(color: AppTheme.BORDER_COLOR),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chat List Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'conversations'.tr(),
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.BORDER_COLOR),

                      // Chat List
                      Expanded(
                        child: chatsAsync.when(
                          data: (chats) {
                            if (chats.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'no_conversations_yet'.tr(),
                                      style: GoogleFonts.manrope(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'chats_will_appear_here'.tr(),
                                      style: GoogleFonts.manrope(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.separated(
                              itemCount: chats.length,
                              separatorBuilder:
                                  (context, index) => const Divider(
                                    height: 1,
                                    color: AppTheme.BORDER_COLOR,
                                    indent: 72,
                                  ),
                              itemBuilder: (context, index) {
                                final chat = chats[index];
                                final isSelected =
                                    selectedChatId.value == chat.id;

                                return Container(
                                  color:
                                      isSelected
                                          ? AppTheme.PRIMARY_COLOR.withOpacity(
                                            0.1,
                                          )
                                          : Colors.transparent,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.PRIMARY_COLOR,
                                      child: Text(
                                        (chat.customerName ??
                                                'unknown_user'.tr())
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: GoogleFonts.manrope(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      chat.customerName ?? 'unknown_user'.tr(),
                                      style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          chat.lastMessage ??
                                              'no_messages_yet'.tr(),
                                          style: GoogleFonts.manrope(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        if (chat.lastMessageAt != null)
                                          Text(
                                            _formatChatTime(
                                              chat.lastMessageAt!,
                                            ),
                                            style: GoogleFonts.manrope(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),

                                    onTap: () {
                                      selectedChatId.value = chat.id;
                                      selectedChat.value = chat;

                                      // Update URL without the chatId parameter when manually selecting
                                      context.go(AppRoutes.messages);
                                    },
                                  ),
                                );
                              },
                            );
                          },
                          loading:
                              () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          error:
                              (error, stack) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'error_loading_chats'.tr(),
                                      style: GoogleFonts.manrope(
                                        color: Colors.red[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      error.toString(),
                                      style: GoogleFonts.manrope(
                                        color: Colors.red[500],
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Chat Messages Area
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child:
                        selectedChatId.value == null
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Unterhaltung auswählen',
                                    style: GoogleFonts.manrope(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Wählen Sie einen Chat aus der Seitenleiste, um mit dem Schreiben zu beginnen',
                                    style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : Column(
                              children: [
                                // Chat Header
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppTheme.PRIMARY_COLOR,
                                        child: Text(
                                          (selectedChat.value?.customerName ??
                                                  'unknown_user'.tr())
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: GoogleFonts.manrope(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              selectedChat
                                                      .value
                                                      ?.customerName ??
                                                  'unknown_user'.tr(),
                                              style: GoogleFonts.manrope(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'Customer',
                                              style: GoogleFonts.manrope(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Messages Area
                                Expanded(
                                  child: Container(
                                    color: const Color(0xFFF8F9FA),
                                    child: Column(
                                      children: [
                                        // Messages List
                                        Expanded(
                                          child: messagesAsync.when(
                                            data: (messages) {
                                              if (messages.isEmpty) {
                                                return Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.message_outlined,
                                                        size: 48,
                                                        color: Colors.grey[400],
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Text(
                                                        'no_messages_in_chat'
                                                            .tr(),
                                                        style:
                                                            GoogleFonts.manrope(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                            ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'start_conversation'
                                                            .tr(),
                                                        style:
                                                            GoogleFonts.manrope(
                                                              color:
                                                                  Colors
                                                                      .grey[500],
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }

                                              return ListView.builder(
                                                controller: scrollController,
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                itemCount: messages.length,
                                                itemBuilder: (context, index) {
                                                  final message =
                                                      messages[index];
                                                  final isAdmin =
                                                      message.senderType ==
                                                      'admin';
                                                  final showTime =
                                                      index == 0 ||
                                                      (index > 0 &&
                                                          messages[index - 1]
                                                                  .createdAt
                                                                  .difference(
                                                                    message
                                                                        .createdAt,
                                                                  )
                                                                  .inMinutes
                                                                  .abs() >
                                                              5);

                                                  return Column(
                                                    children: [
                                                      if (showTime)
                                                        Container(
                                                          margin:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 16,
                                                              ),
                                                          child: Text(
                                                            DateFormat(
                                                              'MMM dd, yyyy - HH:mm',
                                                            ).format(
                                                              message.createdAt,
                                                            ),
                                                            style: GoogleFonts.manrope(
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            isAdmin
                                                                ? MainAxisAlignment
                                                                    .end
                                                                : MainAxisAlignment
                                                                    .start,
                                                        children: [
                                                          Container(
                                                            constraints: BoxConstraints(
                                                              maxWidth:
                                                                  MediaQuery.of(
                                                                    context,
                                                                  ).size.width *
                                                                  0.7,
                                                            ),
                                                            margin:
                                                                const EdgeInsets.only(
                                                                  bottom: 8,
                                                                ),
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 12,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  isAdmin
                                                                      ? AppTheme
                                                                          .PRIMARY_COLOR
                                                                      : Colors
                                                                          .white,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    18,
                                                                  ),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                        0.1,
                                                                      ),
                                                                  blurRadius: 2,
                                                                  offset:
                                                                      const Offset(
                                                                        0,
                                                                        1,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                            child: _buildMessageContent(message, isAdmin),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            loading:
                                                () => const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                            error:
                                                (error, stack) => Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.error_outline,
                                                        size: 48,
                                                        color: Colors.red[400],
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Text(
                                                        'error_loading_messages'
                                                            .tr(),
                                                        style:
                                                            GoogleFonts.manrope(
                                                              color:
                                                                  Colors
                                                                      .red[600],
                                                              fontSize: 16,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                          ),
                                        ),

                                        // Message Input Area
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border(
                                              top: BorderSide(
                                                color: Colors.grey[200]!,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              // Gallery Button (replaced attachment button)
                                              IconButton(
                                                onPressed:
                                                    isUploadingImage.value
                                                        ? null
                                                        : pickAndSendImage,
                                                icon:
                                                    isUploadingImage.value
                                                        ? const SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                              ),
                                                        )
                                                        : Icon(
                                                          Icons.photo_library,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                tooltip: 'send_image'.tr(),
                                              ),

                                              // PDF Button
                                              IconButton(
                                                onPressed:
                                                    isUploadingPdf.value
                                                        ? null
                                                        : pickAndSendPdf,
                                                icon:
                                                    isUploadingPdf.value
                                                        ? const SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                              ),
                                                        )
                                                        : Icon(
                                                          Icons.picture_as_pdf,
                                                          color:
                                                              Colors.red[600],
                                                        ),
                                                tooltip: 'send_pdf'.tr(),
                                              ),

                                              // Message Input Field
                                              Expanded(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFF5F5F5,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          25,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.grey[300]!,
                                                    ),
                                                  ),
                                                  child: TextField(
                                                    controller:
                                                        messageController,
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          'chat_input_hint'
                                                              .tr(),
                                                      hintStyle:
                                                          GoogleFonts.manrope(
                                                            color:
                                                                Colors
                                                                    .grey[600],
                                                          ),
                                                      border: InputBorder.none,
                                                      contentPadding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 20,
                                                            vertical: 12,
                                                          ),
                                                    ),
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 15,
                                                    ),
                                                    maxLines: 4,
                                                    minLines: 1,
                                                    textCapitalization:
                                                        TextCapitalization
                                                            .sentences,
                                                    onSubmitted:
                                                        (value) =>
                                                            sendMessage(),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 12),

                                              // Send Button
                                              Container(
                                                decoration: BoxDecoration(
                                                  color:
                                                      messageText
                                                              .value
                                                              .isNotEmpty
                                                          ? AppTheme
                                                              .PRIMARY_COLOR
                                                          : Colors.grey[400],
                                                  borderRadius:
                                                      BorderRadius.circular(25),
                                                ),
                                                child: IconButton(
                                                  onPressed: sendMessage,
                                                  icon: const Icon(
                                                    Icons.send_rounded,
                                                    color: Colors.white,
                                                    size: 22,
                                                  ),
                                                  splashRadius: 25,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTab(String title, bool isActive, VoidCallback onTap) {
    return HookBuilder(
      builder: (context) {
        final isHovered = useState(false);

        return InkWell(
          onTap: onTap,
          onHover: (hovering) => isHovered.value = hovering,
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight:
                  isActive || isHovered.value
                      ? FontWeight.w600
                      : FontWeight.normal,
              color:
                  isActive
                      ? Colors.black87
                      : isHovered.value
                      ? Colors.black54
                      : Colors.grey[600],
            ),
          ),
        );
      },
    );
  }

  String _formatChatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just_now'.tr();
    } else if (difference.inHours < 1) {
      return 'minutes_ago'.tr(
        namedArgs: {'minutes': difference.inMinutes.toString()},
      );
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }
}
