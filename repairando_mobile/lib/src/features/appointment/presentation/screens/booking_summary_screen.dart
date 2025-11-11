import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/features/appointment/domain/appointment_model.dart';
import 'package:repairando_mobile/src/common/widgets/circle_back_button.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class BookingSummaryScreen extends HookConsumerWidget {
  final AppointmentModel appointmentModel;

  const BookingSummaryScreen({super.key, required this.appointmentModel});

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
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Text('${'date'.tr()}:', style: AppTheme.labelStyle),
                ),
                Expanded(
                  child: Text(
                    appointmentModel.appointmentDate,
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
                  child: Text('${'time'.tr()}:', style: AppTheme.labelStyle),
                ),
                Expanded(
                  child: Text(
                    appointmentModel.appointmentTime,
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
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }
}
