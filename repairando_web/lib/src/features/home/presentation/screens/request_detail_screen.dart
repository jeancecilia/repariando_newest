import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:repairando_web/src/constants/app_images.dart';
import 'package:repairando_web/src/features/home/domain/appointment_model.dart';
import 'package:repairando_web/src/features/home/presentation/controllers/appointment_controller.dart';
import 'package:repairando_web/src/features/home/presentation/controllers/logout_controller.dart';
import 'package:repairando_web/src/router/app_router.dart';
import 'package:repairando_web/src/theme/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_web/src/widgets/custom_popup_menu.dart';
import 'package:repairando_web/src/widgets/make_offer_dialog.dart';
import 'package:repairando_web/src/widgets/vehicle_detail_dialog.dart';
import 'package:easy_localization/easy_localization.dart';

class RequestDetailScreen extends HookConsumerWidget {
  final AppointmentModel appointment;

  const RequestDetailScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(
      text: appointment.issueNote! ?? '',
    );
    return Scaffold(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: AppTheme.LITE_PRIMARY_COLOR,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    context.push(AppRoutes.home);
                  },
                  child: Image.asset(AppImages.APP_LOGO, height: 40),
                ),

                const Spacer(),

                Row(
                  children: [
                    _buildNavTab('upcoming_appointments'.tr(), false, () {
                      context.push(AppRoutes.upcomingAppointment);
                    }),

                    const SizedBox(width: 24),
                    _buildNavTab('service_management'.tr(), false, () {
                      context.push(AppRoutes.serviceManagement);
                    }),
                    const SizedBox(width: 24),
                    _buildNavTab('messages'.tr(), false, () {
                      context.push(AppRoutes.messages);
                    }),
                  ],
                ),

                const Spacer(),
                CustomPopupMenuWidget(
                  onSettingsTap: () {
                    context.go(AppRoutes.workshopSetting);
                  },
                  onLogoutTap: () async {
                    final controller = ref.read(
                      logoutControllerProvider.notifier,
                    );

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (_) =>
                              const Center(child: CircularProgressIndicator()),
                    );

                    await controller.logout();
                    Navigator.of(context).pop();

                    final logoutState = ref.read(logoutControllerProvider);
                    logoutState.whenOrNull(
                      error: (err, _) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(err.toString())));
                      },
                      data: (_) {
                        context.go(AppRoutes.login);
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          Container(
            width: 700,
            margin: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'request_details'.tr(),
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.LITE_PRIMARY_COLOR,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'customer_name'.tr(),
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.TEXT_COLOR,
                              ),
                            ),
                            Text(
                              appointment.customer!.name,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.PRIMARY_COLOR,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'vehicle_type'.tr(),
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.TEXT_COLOR,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  appointment.vehicle!.vehicleName!,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppTheme.PRIMARY_COLOR,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => VehicleDetailsDialog(
                                            appointment: appointment,
                                          ),
                                    );
                                  },
                                  child: Text(
                                    'view_details'.tr(),
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'requested_service'.tr(),
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.TEXT_COLOR,
                              ),
                            ),
                            Text(
                              appointment.service!.service,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.PRIMARY_COLOR,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'detailed_issue_description'.tr(),
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.TEXT_COLOR,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: controller,
                          readOnly: true,
                          maxLines: 5,
                          decoration: AppTheme.textFieldDecoration,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final shouldReject = await _showConfirmationDialog(
                          context,
                          'reject_appointment'.tr(),
                          'reject_appointment_confirmation'.tr(),
                        );

                        if (shouldReject == true) {
                          final success = await ref
                              .read(appointmentStatusUpdateProvider.notifier)
                              .rejectAppointment(appointment.id);

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'appointment_rejected_successfully'.tr(),
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.PRIMARY_COLOR,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        minimumSize: const Size(80, 32),
                      ),
                      child: Text(
                        'reject_request'.tr(),
                        style: GoogleFonts.manrope(fontSize: 12),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder:
                              (_) => MakeOfferDialog(appointment: appointment),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: AppTheme.PRIMARY_COLOR,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.PRIMARY_COLOR),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        minimumSize: const Size(80, 32),
                      ),
                      child: Text(
                        'make_an_offer'.tr(),
                        style: GoogleFonts.manrope(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                Divider(color: AppTheme.BORDER_COLOR),
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

  Future<bool?> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              title,
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            content: Text(message, style: GoogleFonts.manrope()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'cancel'.tr(),
                  style: GoogleFonts.manrope(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.PRIMARY_COLOR,
                  foregroundColor: Colors.white,
                ),
                child: Text('confirm'.tr(), style: GoogleFonts.manrope()),
              ),
            ],
          ),
    );
  }
}
