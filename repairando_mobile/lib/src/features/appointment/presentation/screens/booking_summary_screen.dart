import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/features/appointment/domain/appointment_model.dart';
import 'package:repairando_mobile/src/features/appointment/presentation/controllers/appointment_controller.dart';
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

            // Show Accept/Decline buttons only for offers awaiting response
            if (appointmentModel.appointmentStatus.toLowerCase() == 'awaiting_offer') ...[
              Text(
                'offer_received'.tr(),
                style: AppTheme.appBarTitleStyle.copyWith(
                  fontSize: 16,
                  color: AppTheme.PRIMARY_COLOR,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'offer_decision_prompt'.tr(),
                style: AppTheme.labelStyle.copyWith(fontSize: 12),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final shouldDecline = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('decline_offer'.tr()),
                            content: Text('decline_offer_confirmation'.tr()),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text('cancel'.tr()),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: Text('decline'.tr()),
                              ),
                            ],
                          ),
                        );

                        if (shouldDecline == true && context.mounted) {
                          // Show loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          final success = await ref
                              .read(offerActionControllerProvider.notifier)
                              .declineOffer(appointmentModel.id);

                          if (context.mounted) {
                            Navigator.pop(context); // Close loading

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('offer_declined_successfully'.tr()),
                                  backgroundColor: Colors.orange,
                                ),
                              );

                              // Refresh appointment lists
                              ref.invalidate(pendingAppointmentsControllerProvider);
                              ref.invalidate(offerAvailableAppointmentsControllerProvider);

                              context.pop(); // Go back
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('error_declining_offer'.tr()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'decline_offer'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final shouldAccept = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('accept_offer'.tr()),
                            content: Text('accept_offer_confirmation'.tr()),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text('cancel'.tr()),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.PRIMARY_COLOR,
                                ),
                                child: Text('accept'.tr()),
                              ),
                            ],
                          ),
                        );

                        if (shouldAccept == true && context.mounted) {
                          // Show loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          final success = await ref
                              .read(offerActionControllerProvider.notifier)
                              .acceptOffer(appointmentModel.id);

                          if (context.mounted) {
                            Navigator.pop(context); // Close loading

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('offer_accepted_successfully'.tr()),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              // Refresh appointment lists
                              ref.invalidate(pendingAppointmentsControllerProvider);
                              ref.invalidate(offerAvailableAppointmentsControllerProvider);
                              ref.invalidate(upcomingAppointmentsControllerProvider);

                              context.pop(); // Go back
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('error_accepting_offer'.tr()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.PRIMARY_COLOR,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'accept_offer'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
