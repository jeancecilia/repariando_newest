import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/common/widgets/outlined_primary_button.dart';
import 'package:repairando_mobile/src/common/widgets/primary_button.dart';

showDeleteVehicleDialog(
  BuildContext context, {
  required String vehicleId,
  String? vehicleName,
  String? vehicleImage,
  required VoidCallback onDelete,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    vehicleImage != null && vehicleImage.isNotEmpty
                        ? Image.network(
                          vehicleImage,
                          height: 200.h,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200.h,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.directions_car,
                                size: 60,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        )
                        : Container(
                          height: 200.h,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.directions_car,
                            size: 60,
                            color: Colors.grey[600],
                          ),
                        ),
              ),

              SizedBox(height: 16.h),
              Text(
                'delete_vehicle_dialog_title'.tr(
                  namedArgs: {
                    'vehicleName': vehicleName ?? 'this_vehicle'.tr(),
                  },
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'action_cannot_be_undone'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: 'delete'.tr(),
                      onPressed: () {
                        context.pop(); // Close dialog first
                        onDelete(); // Then execute delete
                      },
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: OutlinedPrimaryButton(
                      text: 'cancel'.tr(),
                      onPressed: () {
                        context.pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
