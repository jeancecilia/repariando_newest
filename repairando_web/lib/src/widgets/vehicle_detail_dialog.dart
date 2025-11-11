import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_web/src/features/home/domain/appointment_model.dart';
import 'package:repairando_web/src/theme/theme.dart';

class VehicleDetailsDialog extends HookConsumerWidget {
  final AppointmentModel appointment;

  const VehicleDetailsDialog({super.key, required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'vehicle_details_title'.tr(),
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Car illustration container
            Container(
              decoration: BoxDecoration(
                color: AppTheme.LITE_PRIMARY_COLOR,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 150,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          appointment.vehicle!.vehicleImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Vehicle title
                    Text(
                      appointment.vehicle!.vehicleName!,
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Vehicle details
                    _buildDetailRow(
                      'vin_label'.tr(),
                      appointment.vehicle!.vin!,
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      'make_model_label'.tr(),
                      "${appointment.vehicle!.vehicleMake} ${appointment.vehicle!.vehicleModel}",
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      'year_of_manufacture_label'.tr(),
                      appointment.vehicle!.vehicleYear!,
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      'engine_type_label'.tr(),
                      appointment.vehicle!.engineType!,
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppTheme.TEXT_COLOR,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppTheme.TEXT_COLOR,
            ),
          ),
        ),
      ],
    );
  }
}
