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
import 'package:repairando_mobile/src/features/appointment/domain/appointment_model.dart';

class PendingAppointmentScreen extends HookConsumerWidget {
  const PendingAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAppointmentsState = ref.watch(
      pendingAppointmentsControllerProvider,
    );

    // Add a separate state for offer available appointments
    final offerAvailableAppointmentsState = ref.watch(
      offerAvailableAppointmentsControllerProvider,
    );

    // Fetch both pending and offer available appointments when the widget is first built
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(pendingAppointmentsControllerProvider.notifier)
            .fetchPendingAppointments();
        ref
            .read(offerAvailableAppointmentsControllerProvider.notifier)
            .fetchOfferAvailableAppointments();
      });
      return null;
    }, []);

    // Get waiting appointments (pending status with price 0.0)
    final waitingAppointments =
        pendingAppointmentsState.appointments
            .where(
              (appointment) =>
                  appointment.appointmentStatus.toLowerCase() == 'pending' ||
                  appointment.price == '0.0',
            )
            .toList();

    // Get offer appointments from the dedicated state (awaiting_offer status)
    final offerAppointments = offerAvailableAppointmentsState.appointments;

    // Show loading if either state is loading
    if (pendingAppointmentsState.isLoading ||
        offerAvailableAppointmentsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error if either state has an error
    if (pendingAppointmentsState.error != null ||
        offerAvailableAppointmentsState.error != null) {
      final error =
          pendingAppointmentsState.error ??
          offerAvailableAppointmentsState.error;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'error_colon'.tr() + error!,
              style: GoogleFonts.manrope(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(pendingAppointmentsControllerProvider.notifier)
                    .fetchPendingAppointments();
                ref
                    .read(offerAvailableAppointmentsControllerProvider.notifier)
                    .fetchOfferAvailableAppointments();
              },
              child: Text('retry'.tr()),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          ExpansionTile(
            title: Text(
              'waiting_workshop_response'.tr(),
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.TEXT_COLOR,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildAppointmentsList(context, waitingAppointments, "Waiting"),
            ],
          ),

          ExpansionTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Text(
              'offers_available'.tr(),
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.TEXT_COLOR,
              ),
            ),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildAppointmentsList(context, offerAppointments, "Offer"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(
    BuildContext context,
    List<AppointmentModel> appointments,
    String type,
  ) {
    if (appointments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          type == "Waiting"
              ? 'no_appointments_waiting_response'.tr()
              : 'no_offers_available'.tr(),
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        final isWaitingType = type == "Waiting";
        final hasPrice = appointment.price != '0.0';

        // Different colors based on type
        final cardColor =
            isWaitingType ? Colors.orange.shade50 : AppTheme.LITE_PRIMARY_COLOR;

        final headerColor =
            isWaitingType ? Colors.orange.shade400 : AppTheme.SECONDAY_COLOR;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: headerColor,
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
                        fontSize: 12,
                      ),
                    ),
                    if (type == 'Offer' && hasPrice)
                      Text(
                        '${'price_offered'.tr()}:  ${formatPrice(double.parse(appointment.price))}',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    if (type == 'Waiting')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'waiting_for_response'.tr(),
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

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
                          const SizedBox(height: 4),
                          Text(
                            appointment.serviceName,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${appointment.vehicleName} ${appointment.vehicleModel} ${appointment.vehicleYear}",
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                            ),
                          ),

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
              if (type == "Offer" && hasPrice)
                Column(
                  children: [
                    const Divider(height: 1),
                    InkWell(
                      onTap: () {
                        context.push(
                          AppRoutes.confirmBookingSummary,
                          extra: appointment,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'check_offer'.tr(),
                              style: GoogleFonts.manrope(
                                color: AppTheme.BLUE_COLOR,
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
            ],
          ),
        );
      },
    );
  }
}
