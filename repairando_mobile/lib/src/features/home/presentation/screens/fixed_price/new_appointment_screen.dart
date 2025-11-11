import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/constants/app_images.dart';
import 'package:repairando_mobile/src/features/home/domain/service_model.dart'
    show ServiceModel;
import 'package:repairando_mobile/src/features/home/domain/workshop_model.dart';
import 'package:repairando_mobile/src/features/profile/domain/vehicle_model.dart';
import 'package:repairando_mobile/src/features/profile/presentation/controllers/vehicle_controller.dart';
import 'package:repairando_mobile/src/router/app_router.dart';
import 'package:repairando_mobile/src/common/widgets/circle_back_button.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class NewAppointmentScreen extends HookConsumerWidget {
  final ServiceModel service;
  final WorkshopModel workshop;

  const NewAppointmentScreen({
    super.key,
    required this.service,
    required this.workshop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(refreshableVehiclesProvider);
    final vehicleController = ref.read(vehicleControllerProvider.notifier);
    // Add this state for selected vehicle
    final selectedVehicleId = useState<String?>(null);
    final selectedVehicle = useState<Vehicle?>(null);

    return Scaffold(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      appBar: AppBar(
        backgroundColor: AppTheme.BACKGROUND_COLOR,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleBackButton(),
        ),
        title: Text('new_appointment'.tr(), style: AppTheme.appBarTitleStyle),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'select_vehicle'.tr(),
                  style: AppTheme.appointmentHeadingTextStyle,
                ),
                GestureDetector(
                  onTap: () {
                    // Handle add vehicle action
                    context.push(AppRoutes.addMyVehicle);
                  },
                  child: Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppTheme.PRIMARY_COLOR,
                    ),
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.BORDER_COLOR),
                borderRadius: BorderRadius.circular(8),
              ),
              child: vehiclesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red[400],
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'error_loading_vehicles'.tr(),
                            style: GoogleFonts.manrope(
                              color: Colors.red[600],
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            error.toString(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              color: Colors.red[500],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton(
                            onPressed: () {
                              vehicleController.refreshVehicles();
                            },
                            child: Text('retry'.tr()),
                          ),
                        ],
                      ),
                    ),
                data: (vehicles) {
                  if (vehicles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'no_vehicles_added_yet'.tr(),
                            style: GoogleFonts.manrope(
                              color: Colors.grey[600],
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'tap_plus_button_add_vehicle'.tr(),
                            style: GoogleFonts.manrope(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Auto-select first vehicle if none selected
                  if (selectedVehicleId.value == null && vehicles.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      selectedVehicle.value = vehicles.first;
                      selectedVehicleId.value = vehicles.first.id.toString();
                    });
                  }

                  // Fixed: Return the ListView.builder
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      final isLast = index == vehicles.length - 1;

                      return Container(
                        decoration: BoxDecoration(
                          border:
                              isLast
                                  ? null
                                  : const Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFE5E5E5),
                                      width: 1,
                                    ),
                                  ),
                        ),
                        child: RadioListTile<String>(
                          value: vehicle.id.toString(),
                          groupValue: selectedVehicleId.value,
                          onChanged: (String? value) {
                            selectedVehicleId.value = value;
                            selectedVehicle.value = vehicles.firstWhere(
                              (v) => v.id.toString() == value,
                            );
                          },
                          title: Text(
                            vehicle.vehicleName
                                .toString(), // Display vehicle name/info
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333),
                            ),
                          ),
                          activeColor: Colors.black,
                          controlAffinity: ListTileControlAffinity.trailing,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'book_service'.tr(),
              style: AppTheme.appointmentHeadingTextStyle,
            ),
            SizedBox(height: 10.h),
            GestureDetector(
              onTap: () {
                // Check if vehicle is selected before proceeding

                if (selectedVehicleId.value != null) {
                  context.push(
                    AppRoutes.scheduleTime,
                    extra: {
                      'selectedVehicle': selectedVehicle.value,
                      'service': service,
                      'workshop': workshop,
                    },
                  );
                } else {
                  // Show snackbar or dialog to select vehicle first
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('please_select_vehicle_first'.tr()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.BORDER_COLOR),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'select_time'.tr(),
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: Color(0xFF333333)),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
