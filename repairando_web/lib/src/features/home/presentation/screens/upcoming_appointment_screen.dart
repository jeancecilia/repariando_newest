import 'package:flutter/material.dart';
import 'package:repairando_web/src/features/home/domain/appointment_model.dart';
import 'package:repairando_web/src/features/home/domain/manual_appointment_model.dart'
    show ManualAppointment;
import 'package:repairando_web/src/features/home/presentation/controllers/appointment_controller.dart';
import 'package:repairando_web/src/features/home/presentation/controllers/manual_appointment_controller.dart';
import 'package:repairando_web/src/features/home/presentation/controllers/chat_controller.dart';
import 'package:repairando_web/src/features/home/presentation/screens/base_layout.dart';
import 'package:repairando_web/src/router/app_router.dart';
import 'package:repairando_web/src/theme/theme.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

class UpcomingAppointmentScreen extends HookConsumerWidget {
  const UpcomingAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final upcomingAppointments = ref.watch(upcomingAppointmentsProvider);
    final manualAppointmentsAsync = ref.watch(manualAppointmentsProvider);
    final deleteState = ref.watch(deleteManualAppointmentControllerProvider);

    // Listen to delete state changes for manual appointments
    ref.listen(deleteManualAppointmentControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (err, _) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${'error_deleting_appointment'.tr()}: ${err.toString()}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          ref
              .read(deleteManualAppointmentControllerProvider.notifier)
              .resetState();
        },
        data: (success) {
          if (success != null && success.isNotEmpty) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            ref
                .read(deleteManualAppointmentControllerProvider.notifier)
                .resetState();
          }
        },
      );
    });

    return BaseLayout(
      title: 'upcoming_appointments'.tr(),
      child: Column(
        children: [
          // Main content
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Title section with refresh button
                  _buildTitleSection(searchController, ref, context),
                  Divider(color: AppTheme.BORDER_COLOR),

                  // Content sections
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Upcoming Appointments Section
                          _buildSectionHeader('upcoming_appointments'.tr()),
                          const SizedBox(height: 16),
                          upcomingAppointments.when(
                            data: (appointments) =>
                                _buildUpcomingAppointmentsTable(
                                  context,
                                  ref,
                                  appointments,
                                ),
                            loading: () => const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (err, st) => SizedBox(
                              height: 200,
                              child: Center(child: Text(err.toString())),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Manual Bookings Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionHeader('manual_bookings'.tr()),
                              ElevatedButton(
                                onPressed: () {
                                  context.push(AppRoutes.addManualAppointment);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.PRIMARY_COLOR,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text('Manuellen Termin hinzufügen'.tr()),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          manualAppointmentsAsync.when(
                            data: (appointments) {
                              if (appointments.isEmpty) {
                                return _buildEmptyManualAppointments(context);
                              }
                              return _buildManualAppointmentsSection(
                                appointments,
                                context,
                                ref,
                                deleteState,
                              );
                            },
                            loading: () => const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (error, stack) =>
                                _buildManualAppointmentsError(
                                  context,
                                  ref,
                                  error,
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
    );
  }

  Widget _buildTitleSection(
    TextEditingController searchController,
    WidgetRef ref,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            'upcoming_appointments'.tr(),
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          // Manual refresh button
          IconButton(
            onPressed: () {
              ref.invalidate(manualAppointmentsProvider);
              ref.invalidate(upcomingAppointmentsProvider);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('appointments_refreshed'.tr()),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'refresh_appointments'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildEmptyManualAppointments(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'no_manual_appointments'.tr(),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                context.push(AppRoutes.addManualAppointment);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.PRIMARY_COLOR,
                foregroundColor: Colors.white,
              ),
              child: Text('create_first_appointment'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualAppointmentsError(
    BuildContext context,
    WidgetRef ref,
    Object error,
  ) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 12),
            Text(
              '${'error_loading_appointments_retry'.tr()}: ${error.toString()}',
              style: TextStyle(fontSize: 14, color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(manualAppointmentsProvider);
              },
              child: Text('retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to parse German date format: "Mittwoch, 20. August"
  DateTime _parseGermanDate(String germanDate) {
    final monthMap = {
      'januar': 1,
      'februar': 2,
      'märz': 3,
      'april': 4,
      'mai': 5,
      'juni': 6,
      'juli': 7,
      'august': 8,
      'september': 9,
      'oktober': 10,
      'november': 11,
      'dezember': 12,
    };

    final parts = germanDate.toLowerCase().replaceAll(',', '').split(' ');
    if (parts.length >= 3) {
      final day = int.tryParse(parts[1].replaceAll('.', ''));
      final monthName = parts[2];
      final month = monthMap[monthName];

      if (day != null && month != null) {
        final year = DateTime.now().year;
        return DateTime(year, month, day);
      }
    }

    return DateTime.now();
  }

  // Helper method to parse time range format: "10:20-11:40"
  DateTime _parseTimeRange(String timeRange) {
    try {
      final startTime = timeRange.split('-')[0].trim();
      final timeParts = startTime.split(':');

      if (timeParts.length == 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        return DateTime(2000, 1, 1, hour, minute);
      }
    } catch (e) {
      // Fallback if parsing fails
    }

    return DateTime(2000, 1, 1, 0, 0);
  }

  Widget _buildUpcomingAppointmentsTable(
    BuildContext context,
    WidgetRef ref,
    List<AppointmentModel> appointments,
  ) {
    // Sort appointments chronologically by date and time
    final sortedAppointments = [...appointments];
    sortedAppointments.sort((a, b) {
      try {
        final dateA = _parseGermanDate(a.appointmentDate ?? '');
        final dateB = _parseGermanDate(b.appointmentDate ?? '');

        if (dateA.isAtSameMomentAs(dateB)) {
          final timeA = _parseTimeRange(a.appointmentTime ?? '00:00-00:00');
          final timeB = _parseTimeRange(b.appointmentTime ?? '00:00-00:00');
          return timeA.compareTo(timeB);
        }

        return dateA.compareTo(dateB);
      } catch (e) {
        final dateComparison = (a.appointmentDate ?? '').compareTo(
          b.appointmentDate ?? '',
        );
        if (dateComparison != 0) return dateComparison;
        return (a.appointmentTime ?? '').compareTo(b.appointmentTime ?? '');
      }
    });

    if (sortedAppointments.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(child: Text("Keine bevorstehenden Termine")),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: AppTheme.LITE_PRIMARY_COLOR,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'date'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'customer_name'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'service_type'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'vehicle_type'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'price'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'time_slot'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'actions'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table rows
          ...sortedAppointments.map(
            (appointment) =>
                _buildUpcomingAppointmentRow(context, ref, appointment),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointmentRow(
    BuildContext context,
    WidgetRef ref,
    AppointmentModel appointment,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              appointment.appointmentDate!,
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              appointment.customer?.fullName ?? 'N/A',
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              appointment.service!.service,
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "${appointment.vehicle!.vehicleMake} ${appointment.vehicle!.vehicleModel}",
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "${appointment.price!}€",
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              appointment.appointmentTime!,
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () async {
                    final shouldCancel = await _showConfirmationDialog(
                      context,
                      'cancel_appointment'.tr(),
                      'cancel_appointment_confirmation'.tr(),
                    );

                    if (shouldCancel == true) {
                      try {
                        final success = await ref
                            .read(appointmentStatusUpdateProvider.notifier)
                            .cancelAppointment(appointment.id);

                        _hideLoadingDialog(context);

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'appointment_cancelled_successfully'.tr(),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          ref.refresh(upcomingAppointmentsProvider);
                        }
                      } catch (e) {
                        _hideLoadingDialog(context);
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.PRIMARY_COLOR,
                    side: const BorderSide(color: AppTheme.PRIMARY_COLOR),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    minimumSize: const Size(60, 32),
                  ),
                  child: Text(
                    'cancel'.tr(),
                    style: GoogleFonts.manrope(fontSize: 12),
                  ),
                ),
                AppointmentMessageButton(appointment: appointment),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualAppointmentsSection(
    List<ManualAppointment> appointments,
    BuildContext context,
    WidgetRef ref,
    AsyncValue<String?> deleteState,
  ) {
    // Sort appointments by date and time for better organization
    final sortedAppointments = List<ManualAppointment>.from(appointments);
    sortedAppointments.sort((a, b) {
      final dateComparison = a.appointmentDate.compareTo(b.appointmentDate);
      if (dateComparison != 0) return dateComparison;
      return a.appointmentTime.compareTo(b.appointmentTime);
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.LITE_PRIMARY_COLOR,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    'customer_name'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'service_name'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'duration'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'time_slot'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'date'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'price'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'status'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'action'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          ...sortedAppointments.map(
            (appointment) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Expanded(flex: 2, child: Text(appointment.serviceName)),
                  Expanded(flex: 1, child: Text(appointment.durationDisplay)),
                  Expanded(flex: 1, child: Text(appointment.appointmentTime)),
                  Expanded(
                    flex: 1,
                    child: Text(
                      appointment.appointmentDate,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "${appointment.price}€",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: _buildStatusChip(appointment.status),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        const SizedBox(width: 5),
                        deleteState.isLoading
                            ? const SizedBox(
                                width: 80,
                                height: 32,
                                child: Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () {
                                  _showDeleteConfirmationDialog(
                                    context,
                                    appointment,
                                    ref,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  minimumSize: const Size(80, 32),
                                ),
                                child: Text(
                                  'delete'.tr(),
                                  style: GoogleFonts.manrope(fontSize: 12),
                                ),
                              ),
                        const SizedBox(width: 5),
                        OutlinedButton(
                          onPressed: () {
                            _showAppointmentDetailsDialog(context, appointment);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.PRIMARY_COLOR,
                            side: const BorderSide(
                              color: AppTheme.PRIMARY_COLOR,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            minimumSize: const Size(60, 32),
                          ),
                          child: Text(
                            'details'.tr(),
                            style: GoogleFonts.manrope(fontSize: 12),
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
    );
  }

  Widget _buildStatusChip(String? status) {
    final statusText = status ?? 'pending';
    Color chipColor;
    Color textColor;

    switch (statusText.toLowerCase()) {
      case 'accepted':
        chipColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'pending':
        chipColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case 'cancelled':
        chipColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      default:
        chipColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          statusText.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    ManualAppointment appointment,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('confirm_delete'.tr()),
        content: Text(
          '${'are_you_sure_delete_appointment'.tr()} ${appointment.customerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(deleteManualAppointmentControllerProvider.notifier)
                  .deleteAppointment(appointment.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _showAppointmentDetailsDialog(
    BuildContext context,
    ManualAppointment appointment,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('appointment_details'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('customer'.tr(), appointment.customerName),
              _buildDetailRow('service'.tr(), appointment.serviceName),
              _buildDetailRow(
                'vehicle'.tr(),
                '${appointment.vehicleMake} ${appointment.vehicleModel} (${appointment.vehicleYear})',
              ),
              _buildDetailRow('date'.tr(), appointment.appointmentDate),
              _buildDetailRow('time'.tr(), appointment.timeSlotDisplay),
              _buildDetailRow(
                'duration_display'.tr(),
                appointment.durationDisplay,
              ),
              _buildDetailRow('price'.tr(), '${appointment.price}€'),
              _buildDetailRow('email'.tr(), appointment.emailAddress),
              _buildDetailRow('phone'.tr(), appointment.phoneNumber),
              _buildDetailRow('status'.tr(), appointment.status ?? 'pending'),
              if (appointment.additionalNotes != null &&
                  appointment.additionalNotes!.isNotEmpty)
                _buildDetailRow('notes'.tr(), appointment.additionalNotes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('close'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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

  void _hideLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}

class AppointmentMessageButton extends HookConsumerWidget {
  const AppointmentMessageButton({super.key, required this.appointment});

  final AppointmentModel appointment;

  static const messageButtonKey = Key('upcomingAppointmentMessageButton');

  bool get _canShowButton {
    final customer = appointment.customer;
    if (customer == null) {
      return false;
    }

    return customer.id.isNotEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_canShowButton) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: OutlinedButton(
        key: messageButtonKey,
        onPressed: () async {
          final currentUserId = ref.read(currentUserProvider);
          final customerId = appointment.customer?.id;

          if (currentUserId != null && customerId != null) {
            try {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final messagesController = ref.read(
                messagesControllerProvider.notifier,
              );
              final chat = await messagesController.initiateChatWithCustomerId(
                customerId: customerId,
                currentUserId: currentUserId,
                initialMessage: null,
              );

              Navigator.of(context).pop();

              if (chat != null) {
                context.go('${AppRoutes.messages}?chatId=${chat.id}');
              }
            } catch (e) {
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.PRIMARY_COLOR,
          side: const BorderSide(color: AppTheme.PRIMARY_COLOR),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          minimumSize: const Size(60, 32),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('message'.tr(), style: GoogleFonts.manrope(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
