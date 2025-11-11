import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/constants/app_images.dart';
import 'package:repairando_mobile/src/features/profile/presentation/controllers/vehicle_controller.dart';
import 'package:repairando_mobile/src/features/profile/presentation/screens/delete_vehicle_dialog.dart';
import 'package:repairando_mobile/src/router/app_router.dart';
import 'package:repairando_mobile/src/common/widgets/circle_back_button.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class ViewVehicleScreen extends HookConsumerWidget {
  const ViewVehicleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(refreshableVehiclesProvider);
    final vehicleController = ref.read(vehicleControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(AppRoutes.addMyVehicle);
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'add_vehicle_button'.tr(),
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.PRIMARY_COLOR,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      appBar: AppBar(
        backgroundColor: AppTheme.BACKGROUND_COLOR,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleBackButton(),
        ),
        title: Text(
          'view_vehicle_screen_title'.tr(),
          style: GoogleFonts.manrope(
            color: Colors.black,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
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
      body: RefreshIndicator(
        onRefresh: () async {
          await vehicleController.refreshVehicles();
        },
        child: vehiclesAsync.when(
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
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        color: Colors.grey[600],
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'tap_plus_button_add_vehicle'.tr(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: vehicles.length,
              padding: EdgeInsets.only(bottom: 80.h), // Space for FAB
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.LITE_PRIMARY_COLOR,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vehicle Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                vehicle.vehicleImage != null &&
                                        vehicle.vehicleImage!.isNotEmpty
                                    ? Image.network(
                                      vehicle.vehicleImage!,
                                      height: 200.h,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
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
                          SizedBox(height: 10.h),

                          // Vehicle Name
                          Text(
                            vehicle.vehicleName!,
                            style: GoogleFonts.manrope(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 10.h),

                          // VIN
                          if (vehicle.vin != null && vehicle.vin!.isNotEmpty)
                            _buildInfoRow('vin_colon'.tr(), vehicle.vin!),

                          if (vehicle.vin != null && vehicle.vin!.isNotEmpty)
                            SizedBox(height: 10.h),

                          // Make & Model
                          _buildInfoRow(
                            'make_model_colon'.tr(),
                            '${vehicle.vehicleMake ?? ''} ${vehicle.vehicleModel ?? ''} ${vehicle.vehicleYear ?? ''}'
                                .trim(),
                          ),
                          SizedBox(height: 10.h),

                          // Engine Type
                          if (vehicle.engineType != null &&
                              vehicle.engineType!.isNotEmpty)
                            _buildInfoRow(
                              'engine_type_colon'.tr(),
                              vehicle.engineType!,
                            ),

                          if (vehicle.engineType != null &&
                              vehicle.engineType!.isNotEmpty)
                            SizedBox(height: 10.h),

                          // Mileage
                          if (vehicle.mileage != null &&
                              vehicle.mileage!.isNotEmpty)
                            _buildInfoRow(
                              'mileage_colon'.tr(),
                              vehicle.mileage!,
                            ),

                          SizedBox(height: 20.h),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    side: const BorderSide(
                                      color: AppTheme.PRIMARY_COLOR,
                                      width: 2,
                                    ),
                                  ),
                                  onPressed: () {
                                    context.push(
                                      AppRoutes.editMyVehicle,
                                      extra: vehicle.id!,
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(AppImages.EDIT_IMAGE),
                                      SizedBox(width: 10.w),
                                      Text(
                                        'edit'.tr(),
                                        style: GoogleFonts.manrope(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.PRIMARY_COLOR,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.PRIMARY_COLOR,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    showDeleteVehicleDialog(
                                      context,
                                      vehicleImage: vehicle.vehicleImage,
                                      vehicleId: vehicle.id!,
                                      vehicleName: vehicle.vehicleName,
                                      onDelete: () async {
                                        // Show loading indicator
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder:
                                              (context) => const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                        );

                                        try {
                                          await vehicleController.deleteVehicle(
                                            vehicle.id!,
                                          );

                                          // Close loading dialog
                                          if (context.mounted) {
                                            context.pop();
                                          }

                                          // Show success message
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'vehicle_deleted_successfully'
                                                      .tr(),
                                                  style: GoogleFonts.manrope(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                backgroundColor: Colors.green,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          // Close loading dialog
                                          if (context.mounted) {
                                            context.pop();
                                          }

                                          // Show error message
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${'failed_to_delete_vehicle'.tr()} ${e.toString()}',
                                                  style: GoogleFonts.manrope(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                backgroundColor: Colors.red,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(AppImages.DELETE_WHIE_IMAGE),
                                      SizedBox(width: 10.w),
                                      Text(
                                        'delete'.tr(),
                                        style: GoogleFonts.manrope(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.BACKGROUND_COLOR,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
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
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.manrope(
              color: AppTheme.TEXT_COLOR,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.manrope(
              color: AppTheme.TEXT_COLOR,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
