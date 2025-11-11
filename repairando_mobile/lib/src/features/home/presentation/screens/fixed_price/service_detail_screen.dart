import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/constants/app_constants.dart';
import 'package:repairando_mobile/src/constants/app_images.dart';
import 'package:repairando_mobile/src/features/home/domain/service_model.dart';
import 'package:repairando_mobile/src/features/home/domain/workshop_model.dart';
import 'package:repairando_mobile/src/features/messages/domain/chat_model.dart';
import 'package:repairando_mobile/src/features/messages/presentation/controllers/chat_controller.dart';
import 'package:repairando_mobile/src/router/app_router.dart';
import 'package:repairando_mobile/src/common/widgets/circle_back_button.dart';
import 'package:repairando_mobile/src/common/widgets/outlined_primary_button.dart';
import 'package:repairando_mobile/src/common/widgets/primary_button.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class ServiceDetailScreen extends HookConsumerWidget {
  final ServiceModel service;
  final WorkshopModel workshop;

  const ServiceDetailScreen({
    super.key,
    required this.service,
    required this.workshop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      appBar: AppBar(
        backgroundColor: AppTheme.BACKGROUND_COLOR,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleBackButton(),
        ),
        title: Text('service_detail'.tr(), style: AppTheme.appBarTitleStyle),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                context.push(AppRoutes.notification);
              },
              child: Image.asset(AppImages.NOTIFICATION_ICON, height: 25.h),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.serviceName ?? '', style: AppTheme.appBarTitleStyle),
            SizedBox(height: 10.h),
            Text(
              service.description ?? '',
              textAlign: TextAlign.left,
              style: AppTheme.serviceDetailParagraph,
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("price".tr(), style: AppTheme.workshopNameStyle),
                Text(
                  formatPrice(service.price),
                  style: AppTheme.workshopNameStyle,
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('time_duration'.tr(), style: AppTheme.workshopNameStyle),
                Text(
                  "${int.parse(service.durationMinutes) * 6} minutes",
                  style: AppTheme.workshopNameStyle,
                ),
              ],
            ),
            SizedBox(height: 20.h),
            PrimaryButton(
              text: 'send_message'.tr(),
              onPressed: () {
                _handleChatButtonPressed(context, ref);
              },
            ),
            SizedBox(height: 20.h),
            OutlinedPrimaryButton(
              text: 'book_appointment'.tr(),
              onPressed: () {
                context.push(
                  AppRoutes.newAppointment,
                  extra: {'service': service, 'workshop': workshop},
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Handle chat button pressed with proper validation and error handling
  Future<void> _handleChatButtonPressed(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Validate workshop user ID
    if (workshop.userId == null || workshop.userId!.isEmpty) {
      _showErrorSnackBar(context, 'Workshop information is incomplete');
      return;
    }

    // Validate UUID format
    if (!_isValidUUID(workshop.userId!)) {
      _showErrorSnackBar(context, 'Invalid workshop ID format');
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      _showErrorSnackBar(context, 'Please login to start a chat');
      return;
    }

    // Check if user is trying to chat with themselves
    if (currentUser.id == workshop.userId) {
      _showErrorSnackBar(context, 'You cannot start a chat with yourself');
      return;
    }

    try {
      final chatController = ref.read(chatControllerProvider.notifier);
      final repository = ref.read(chatRepositoryProvider);

      // Use getOrCreateChatBetweenUsers instead of getOrCreateChatForAppointment
      // since you want to chat directly with the workshop owner, not based on an appointment
      final chat = await repository.getOrCreateChatBetweenUsers(
        currentUserId: currentUser.id,
        otherUserId: workshop.userId!,
        isCurrentUserAdmin:
            false, // Current user is customer, workshop owner is admin
      );

      // Navigate to the chat
      _navigateToChat(context, chat);
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to start chat: ${e.toString()}');
    }
  }

  bool _isValidUUID(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(uuid);
  }

  // Navigate to chat screen
  void _navigateToChat(BuildContext context, Chat chat) {
    context.push(
      AppRoutes.workshopMessages,
      extra: {
        'chatId': chat.id,
        'chatName': workshop.workshopName ?? 'Workshop',
        'otherUserImage': workshop.profileImageUrl,
      },
    );
  }

  // Show error message
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
