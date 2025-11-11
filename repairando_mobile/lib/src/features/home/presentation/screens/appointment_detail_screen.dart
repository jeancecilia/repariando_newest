import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_mobile/src/constants/app_constants.dart';
import 'package:repairando_mobile/src/features/home/domain/service_model.dart';
import 'package:repairando_mobile/src/features/home/domain/workshop_model.dart';
import 'package:repairando_mobile/src/features/home/presentation/controllers/appointment_controller.dart';
import 'package:repairando_mobile/src/features/profile/domain/vehicle_model.dart';
import 'package:repairando_mobile/src/common/widgets/circle_back_button.dart';
import 'package:repairando_mobile/src/common/widgets/primary_button.dart';
import 'package:repairando_mobile/src/theme/theme.dart';
import 'package:easy_localization/easy_localization.dart';

class AppointmentDetailScreen extends HookConsumerWidget {
  final ServiceModel service;
  final Vehicle vehicle;
  final String timeSlot;
  final String selectedDate;
  final WorkshopModel workshop;

  const AppointmentDetailScreen({
    super.key,
    required this.service,
    required this.vehicle,
    required this.timeSlot,
    required this.selectedDate,
    required this.workshop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentCreation = ref.watch(appointmentCreationProvider);
    final issueNoteController = TextEditingController();

    ref.listen<AsyncValue<void>>(appointmentCreationProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Appointment created successfuly')),
          );
          ref.read(appointmentCreationProvider.notifier).clearState();

          context.pop();
          context.pop();
          context.pop();
          context.pop();
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appointment failed to create'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });

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
          'appointment_details'.tr(),
          style: AppTheme.appBarTitleStyle,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('booking_summary'.tr(), style: AppTheme.appBarTitleStyle),
            SizedBox(height: 30.h),

            // Booking details
            _infoRow('date'.tr(), selectedDate),
            SizedBox(height: 10),
            _infoRow('time'.tr(), timeSlot),
            SizedBox(height: 10),
            _infoRow('workshop'.tr(), workshop.workshopName!),
            SizedBox(height: 10),
            _infoRow('service_type'.tr(), service.serviceName!),
            SizedBox(height: 10),
            _infoRow('price'.tr(), formatPrice(service.price)),
            SizedBox(height: 10),
            _infoRow(
              'vehicle'.tr(),
              '${vehicle.vehicleName}, ${vehicle.vehicleModel} & ${vehicle.vehicleMake}',
            ),

            SizedBox(height: 30.h),

            // Book appointment button
            PrimaryButton(
              text: 'book_appointment'.tr(),
              onPressed:
                  appointmentCreation.isLoading
                      ? null
                      : () {
                        ref
                            .read(appointmentCreationProvider.notifier)
                            .createAppointment(
                              neededWorkUnit: service.durationMinutes,
                              workshopId: workshop.userId.toString(),
                              vehicleId: vehicle.id!,
                              serviceId: service.serviceId.toString(),
                              price: service.price.toString(),
                              appointmentTime: timeSlot,
                              appointmentDate: selectedDate,
                              issueNote:
                                  issueNoteController.text.isEmpty
                                      ? null
                                      : issueNoteController.text,
                            );
                      },
              child:
                  appointmentCreation.isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppTheme.labelStyle)),
          Expanded(child: Text(value, style: AppTheme.labelStyle)),
        ],
      ),
    );
  }
}
