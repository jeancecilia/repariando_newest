import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:repairando_mobile/src/constants/app_images.dart';
import 'package:repairando_mobile/src/features/appointment/data/appointment_repository.dart';
import 'package:repairando_mobile/src/features/appointment/domain/appointment_model.dart';
import 'package:repairando_mobile/src/features/appointment/presentation/screens/time_selection_bottom_sheet.dart';
import 'package:repairando_mobile/src/router/app_router.dart';
import 'package:repairando_mobile/src/common/widgets/circle_back_button.dart';
import 'package:repairando_mobile/src/common/widgets/outlined_primary_button.dart';
import 'package:repairando_mobile/src/common/widgets/primary_button.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class ConfirmBookingSummaryScreen extends HookConsumerWidget {
  final AppointmentModel appointmentModel;

  const ConfirmBookingSummaryScreen({super.key, required this.appointmentModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = useState<String?>(null);
    final selectedTime = useState<String?>(null);
    final isLoading = useState<bool>(false);

    Future<void> selectDateTime() async {
      final result = await showModalBottomSheet<Map<String, String>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (context) => TimeSlotSelectionBottomSheet(
              appointmentModel: appointmentModel,
            ),
      );

      if (result != null) {
        selectedDate.value = result['date'];
        selectedTime.value = result['time'];
      }
    }

    // Helper method to check if date and time are selected
    bool isDateTimeSelected() {
      return selectedDate.value != null &&
          selectedTime.value != null &&
          selectedDate.value!.trim().isNotEmpty &&
          selectedTime.value!.trim().isNotEmpty;
    }

    Future<void> confirmBooking() async {
      // Enhanced validation: Check for both null and empty string
      if (!isDateTimeSelected()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('please_select_date_time'.tr()),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      isLoading.value = true;

      try {
        final repository = AppointmentRepository();
        final success = await repository.confirmAppointmentOffer(
          appointmentModel.id,
          selectedDate.value!,
          selectedTime.value!,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('booking_confirmed_successfully'.tr()),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back to appointments or home
          context.pop();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_to_confirm_booking'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        isLoading.value = false;
      }
    }

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
            Text('booking_summary'.tr(), style: AppTheme.appBarTitleStyle),
            SizedBox(height: 30.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${'workshop'.tr()}:',
                    style: AppTheme.labelStyle,
                  ),
                ),
                Expanded(
                  child: Text(
                    appointmentModel.workshopName,
                    style: AppTheme.labelStyle,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${'service_type'.tr()}:',
                    style: AppTheme.labelStyle,
                  ),
                ),
                Expanded(
                  child: Text(
                    appointmentModel.serviceName,
                    style: AppTheme.labelStyle,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Text('${'price'.tr()}:', style: AppTheme.labelStyle),
                ),
                Expanded(
                  child: Text(
                    '${appointmentModel.price} €',
                    style: AppTheme.labelStyle,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Text('${'vehicle'.tr()}:', style: AppTheme.labelStyle),
                ),
                Expanded(
                  child: Text(
                    "${appointmentModel.vehicleName} ${appointmentModel.vehicleModel} & ${appointmentModel.vehicleYear}",
                    style: AppTheme.labelStyle,
                  ),
                ),
              ],
            ),

            SizedBox(height: 15.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        '${'select_date_time'.tr()}:',
                        style: AppTheme.labelStyle,
                      ),
                      Text(
                        ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: selectDateTime,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFECEFF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: !isDateTimeSelected() ? Colors.red.shade300 : Colors.grey.shade300,
                          width: !isDateTimeSelected() ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedDate.value != null &&
                                      selectedTime.value != null
                                  ? '${selectedDate.value}, ${selectedTime.value}'
                                  : 'tap_to_select_date_time'.tr(),
                              style: TextStyle(
                                color:
                                    selectedDate.value != null
                                        ? Colors.black
                                        : Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(Icons.access_time, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30.h),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text:
                        isLoading.value
                            ? 'confirming'.tr()
                            : 'confirm_booking'.tr(),
                    onPressed: isLoading.value || !isDateTimeSelected()
                        ? null
                        : confirmBooking,
                  ),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: OutlinedPrimaryButton(
                    text: 'cancel'.tr(),
                    onPressed: () {
                      isLoading.value ? null : context.pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
