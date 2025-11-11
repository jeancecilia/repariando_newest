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
import 'package:repairando_mobile/src/features/appointment/presentation/controllers/appointment_controller.dart';

class PastAppointmentScreen extends HookConsumerWidget {
  const PastAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pastAppointmentsState = ref.watch(pastAppointmentsControllerProvider);
    final hasInitialized = useRef(false);

    // Show error messages
    ref.listen(pastAppointmentsControllerProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_colon'.tr() + next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(pastAppointmentsControllerProvider.notifier).clearError();
      }
    });

    // Initialize data only once
    useEffect(() {
      if (!hasInitialized.value) {
        hasInitialized.value = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(pastAppointmentsControllerProvider.notifier)
              .fetchPastAppointments();
        });
      }
      return null;
    }, []);

    if (pastAppointmentsState.isLoading &&
        pastAppointmentsState.appointments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pastAppointmentsState.appointments.isEmpty &&
        !pastAppointmentsState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'no_past_appointments_found'.tr(),
              style: GoogleFonts.manrope(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'past_appointments_will_appear'.tr(),
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(pastAppointmentsControllerProvider.notifier)
                    .fetchPastAppointments();
              },
              child: Text('retry'.tr()),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(pastAppointmentsControllerProvider.notifier)
            .fetchPastAppointments();
      },
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: pastAppointmentsState.appointments.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (context, index) {
          final appointment = pastAppointmentsState.appointments[index];

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.LITE_PRIMARY_COLOR,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.appointmentStatus),
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
                      Expanded(
                        child: Text(
                          appointment.appointmentDate,
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            appointment.appointmentTime,
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _getStatusText(appointment.appointmentStatus),
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child:
                            appointment.workshopImage != null &&
                                    appointment.workshopImage!.isNotEmpty
                                ? Image.network(
                                  appointment.workshopImage!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appointment.serviceName,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getVehicleDisplayText(appointment),
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (appointment.price.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${formatPrice(double.parse(appointment.price))}',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.PRIMARY_COLOR,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
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
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return const Color.fromARGB(255, 255, 59, 203);
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.blue;
      case 'accepted':
        return AppTheme.SECONDAY_COLOR;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'completed'.tr();
      case 'cancelled':
        return 'cancelled'.tr();
      case 'rejected':
        return 'rejected'.tr();
      case 'pending':
        return 'pending'.tr();
      case 'accepted':
        return 'accepted'.tr();
      default:
        return status.toUpperCase();
    }
  }

  String _getVehicleDisplayText(appointment) {
    final parts = <String>[];

    if (appointment.vehicleMake != null && appointment.vehicleMake.isNotEmpty) {
      parts.add(appointment.vehicleMake);
    }
    if (appointment.vehicleName != null && appointment.vehicleName.isNotEmpty) {
      parts.add(appointment.vehicleName);
    }
    if (appointment.vehicleYear != null && appointment.vehicleYear.isNotEmpty) {
      parts.add(appointment.vehicleYear);
    }

    if (parts.isEmpty) return 'vehicle_information_not_available'.tr();

    return parts.join(' ');
  }
}
