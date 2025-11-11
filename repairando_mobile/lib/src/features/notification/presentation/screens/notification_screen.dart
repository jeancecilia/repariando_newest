import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/constants/app_images.dart';
import 'package:repairando_mobile/src/common/widgets/circle_back_button.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class NotificationsScreen extends HookConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      appBar: AppBar(
        backgroundColor: AppTheme.BACKGROUND_COLOR,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleBackButton(),
        ),
        title: Text(
          'notifications_screen_title'.tr(),
          style: AppTheme.appBarTitleStyle,
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                // Mark all as read functionality
              },
              child: Text(
                'notifications_mark_all_read'.tr(),
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Color(0xFFB20000),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Notifications List
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildNotificationItem(
                      title: 'notifications_new_message_title'.tr(),
                      message: 'notifications_new_message_text'.tr(),
                      time: 'notifications_time_placeholder'.tr(),
                    ),

                    const Divider(
                      color: Color(0xFFF2F2F7),
                      thickness: 1,
                      height: 32,
                    ),

                    _buildNotificationItem(
                      title: 'notifications_appointment_reminder_title'.tr(),
                      message: 'notifications_appointment_reminder_text'.tr(),
                      time: 'notifications_time_placeholder'.tr(),
                    ),

                    const Divider(
                      color: Color(0xFFF2F2F7),
                      thickness: 1,
                      height: 32,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String message,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 20.h),
          child: Image.asset(AppImages.NOTIFICATION_SCREEN_ICON, height: 25.h),
        ),
        SizedBox(width: 20.w),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 20.w),
        Text(
          time,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
