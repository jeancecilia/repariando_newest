// lib/src/features/appointment/presentation/screens/upcoming_appointment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/constants/app_constants.dart';
import 'package:repairando_mobile/src/constants/app_images.dart';
import 'package:repairando_mobile/src/router/app_router.dart';
import 'package:repairando_mobile/src/theme/theme.dart';
import '../controllers/appointment_controller.dart';

class UpcomingAppointmentScreen extends HookConsumerWidget {
  const UpcomingAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentState = ref.watch(upcomingAppointmentsControllerProvider);
    final appointmentController = ref.read(
      upcomingAppointmentsControllerProvider.notifier,
    );

    useEffect(() {
      // Fetch appointments when the screen loads
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appointmentController.fetchUpcomingAppointments();
      });
      return null;
    }, []);

    // Show error snackbar if there's an error
    useEffect(() {
      if (appointmentState.error != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(appointmentState.error!),
              backgroundColor: Colors.red,
            ),
          );
          appointmentController.clearError();
        });
      }
      return null;
    }, [appointmentState.error]);

    if (appointmentState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (appointmentState.appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              'no_upcoming_appointments'.tr(),
              style: GoogleFonts.manrope(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await appointmentController.fetchUpcomingAppointments();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: appointmentState.appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointmentState.appointments[index];

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.LITE_PRIMARY_COLOR,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date and Time Header
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.SECONDAY_COLOR,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        appointment.appointmentDate,
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        appointment.appointmentTime,
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Appointment Details
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child:
                            appointment.workshopImage != null
                                ? Image.network(
                                  appointment.workshopImage!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      "assets/images/png/auto_repair.png",
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                                : Image.asset(
                                  "assets/images/png/auto_repair.png",
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                      ),
                      const SizedBox(width: 12),

                      // Appointment Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appointment.workshopName,
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.TEXT_COLOR,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              appointment.serviceName,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              appointment.vehicleName,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Colors.black54,
                              ),
                            ),
                            if (appointment.price.isNotEmpty) ...[
                              SizedBox(height: 4),
                              Text(
                                '${formatPrice(double.parse(appointment.price))}',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.BLUE_COLOR,
                                ),
                              ),
                            ],
                            SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                context.push(
                                  AppRoutes.bookingSummary,
                                  extra: appointment,
                                );
                              },
                              child: Container(
                                width: 130.w,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.PRIMARY_COLOR.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'view_details'.tr(),
                                      style: GoogleFonts.manrope(
                                        color: AppTheme.PRIMARY_COLOR,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),

                                    Image.asset(
                                      AppImages.ARROW_UP_IMAGE,
                                      width: 20,
                                      height: 20,
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
                ),

                // Cancel Button
                const Divider(height: 1),
                InkWell(
                  onTap: () {
                    _showCancelConfirmationDialog(
                      context,
                      appointment.id.toString(),
                      appointmentController,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'cancel_appointment'.tr(),
                          style: GoogleFonts.manrope(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCancelConfirmationDialog(
    BuildContext context,
    String appointmentId,
    UpcomingAppointmentsController controller,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'cancel_appointment_dialog_title'.tr(),
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.TEXT_COLOR,
            ),
          ),
          content: Text(
            'cancel_appointment_dialog_message'.tr(),
            style: GoogleFonts.manrope(fontSize: 14, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'no'.tr(),
                style: GoogleFonts.manrope(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await controller.cancelAppointment(appointmentId);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('appointment_cancelled_successfully'.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text(
                'yes_cancel'.tr(),
                style: GoogleFonts.manrope(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
