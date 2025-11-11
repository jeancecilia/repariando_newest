import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/constants/app_constants.dart';
import 'package:repairando_mobile/src/constants/app_images.dart';
import 'package:repairando_mobile/src/features/profile/presentation/controllers/vehicle_controller.dart';
import 'package:repairando_mobile/src/router/app_router.dart';
import 'package:repairando_mobile/src/common/widgets/circle_back_button.dart';
import 'package:repairando_mobile/src/common/widgets/primary_button.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class EditMyVehicleScreen extends HookConsumerWidget {
  final String vehicleId;

  const EditMyVehicleScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final vehicleNameController = useTextEditingController();
    final vinController = useTextEditingController();
    final vehicleMakeController = useTextEditingController();
    final vehicleModelController = useTextEditingController();
    final selectedYear = useTextEditingController();

    final selectedEngineType = useState<String?>(null);
    final selectedMileaAge = useState<String?>(null);
    final vehicleImage = useState<File?>(null);
    final currentVehicleImageUrl = useState<String?>(null);
    final isDataLoaded = useState<bool>(false);

    // Watch the vehicle controller state
    final vehicleState = ref.watch(vehicleControllerProvider);
    final vehicleController = ref.read(vehicleControllerProvider.notifier);

    // Watch vehicles to get current vehicle data
    final vehiclesAsync = ref.watch(refreshableVehiclesProvider);

    // Load vehicle data when screen opens
    useEffect(() {
      vehiclesAsync.whenData((vehicles) {
        if (!isDataLoaded.value) {
          final vehicle = vehicles.firstWhere(
            (v) => v.id == vehicleId,
            orElse: () => throw Exception('vehicle_not_found'.tr()),
          );

          // Populate form fields with existing data
          vehicleNameController.text = vehicle.vehicleName ?? '';
          vinController.text = vehicle.vin ?? '';
          vehicleMakeController.text = vehicle.vehicleMake ?? '';
          vehicleModelController.text = vehicle.vehicleModel ?? '';
          selectedYear.text = vehicle.vehicleYear ?? '';
          selectedEngineType.value = vehicle.engineType;
          selectedMileaAge.value = vehicle.mileage;
          currentVehicleImageUrl.value = vehicle.vehicleImage;

          isDataLoaded.value = true;
        }
      });
      return null;
    }, [vehiclesAsync]);

    // Listen to controller state changes for UI feedback
    ref.listen<AsyncValue<void>>(vehicleControllerProvider, (previous, next) {
      next.when(
        data: (_) {
          if (previous?.isLoading == true) {
            // Success - vehicle was updated
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('vehicle_updated_successfully'.tr()),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate back
            Navigator.of(context).pop();
          }
        },
        loading: () {
          // Loading state is handled by the button
        },
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'error_prefix'.tr()}${error.toString()}'),
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
          'edit_vehicle'.tr(),
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
      body: vehiclesAsync.when(
        data: (vehicles) {
          try {
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('vehicle_images'.tr(), style: AppTheme.labelStyle),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final pickedImage =
                            await vehicleController.pickVehicleImage();
                        if (pickedImage != null) {
                          vehicleImage.value = pickedImage;
                          currentVehicleImageUrl.value =
                              null; // Clear current URL when new image is selected
                        }
                      },
                      child: Container(
                        height: 150.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppTheme.LITE_PRIMARY_COLOR,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.BACKGROUND_COLOR,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _buildImageWidget(
                              vehicleImage.value,
                              currentVehicleImageUrl.value,
                              onRemove: () {
                                vehicleImage.value = null;
                                currentVehicleImageUrl.value = null;
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30.h),

                    Text(
                      'vehicle_information'.tr(),
                      style: AppTheme.labelStyle,
                    ),
                    SizedBox(height: 24.h),

                    _buildTextField(
                      label: 'vehicle_name'.tr(),
                      controller: vehicleNameController,
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'required'.tr()
                                  : null,
                    ),
                    SizedBox(height: 20.h),

                    _buildTextField(
                      label: 'vin_label'.tr(),
                      controller: vinController,
                      hintText: 'vin_hint'.tr(),
                    ),
                    SizedBox(height: 20.h),

                    _buildTextField(
                      label: 'vehicle_make'.tr(),
                      controller: vehicleMakeController,
                    ),
                    SizedBox(height: 20.h),

                    _buildTextField(
                      label: 'vehicle_model'.tr(),
                      controller: vehicleModelController,
                      hintText: 'vehicle_model_hint'.tr(),
                    ),
                    SizedBox(height: 20.h),

                    _buildTextField(
                      label: 'year_of_manufacture'.tr(),
                      controller: selectedYear,
                      hintText: 'year_of_manufacture_hint'.tr(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'required'.tr();
                        }
                        final year = int.tryParse(value);
                        if (year == null ||
                            year < 1900 ||
                            year > DateTime.now().year) {
                          return 'enter_valid_year'.tr();
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),

                    _buildDropdownField(
                      label: 'engine_type'.tr(),
                      value: selectedEngineType.value,
                      hint: 'engine_type_hint'.tr(),
                      items: AppConstants.ENGINE_TYPES,
                      onChanged: (value) => selectedEngineType.value = value,
                      validator:
                          (value) =>
                              value == null
                                  ? 'select_engine_type_validation'.tr()
                                  : null,
                    ),
                    SizedBox(height: 20.h),

                    _buildDropdownField(
                      label: 'mileage'.tr(),
                      value: selectedMileaAge.value,
                      hint: 'mileage_hint'.tr(),
                      items: AppConstants.MILEAGE,
                      onChanged: (value) => selectedMileaAge.value = value,
                      validator:
                          (value) =>
                              value == null
                                  ? 'select_mileage_validation'.tr()
                                  : null,
                    ),

                    SizedBox(height: 40.h),

                    PrimaryButton(
                      text:
                          vehicleState.isLoading
                              ? 'updating'.tr()
                              : 'update_vehicle'.tr(),
                      onPressed:
                          vehicleState.isLoading
                              ? null
                              : () async {
                                if (formKey.currentState!.validate()) {
                                  await vehicleController.updateVehicle(
                                    vehicleId: vehicleId,
                                    vehicleName:
                                        vehicleNameController.text.trim(),
                                    vin:
                                        vinController.text.trim().isEmpty
                                            ? null
                                            : vinController.text.trim(),
                                    vehicleMake:
                                        vehicleMakeController.text
                                                .trim()
                                                .isEmpty
                                            ? null
                                            : vehicleMakeController.text.trim(),
                                    vehicleModel:
                                        vehicleModelController.text
                                                .trim()
                                                .isEmpty
                                            ? null
                                            : vehicleModelController.text
                                                .trim(),
                                    vehicleYear:
                                        selectedYear.text.trim().isEmpty
                                            ? null
                                            : selectedYear.text.trim(),
                                    engineType: selectedEngineType.value,
                                    mileage: selectedMileaAge.value,
                                    newVehicleImage: vehicleImage.value,
                                  );
                                }
                              },
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            );
          } catch (e) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                  SizedBox(height: 16.h),
                  Text(
                    'vehicle_not_found'.tr(),
                    style: GoogleFonts.manrope(
                      color: Colors.red[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('go_back'.tr()),
                  ),
                ],
              ),
            );
          }
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
                    'error_loading_vehicle_data'.tr(),
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
                      ref.refresh(refreshableVehiclesProvider);
                    },
                    child: Text('retry'.tr()),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildImageWidget(
    File? newImage,
    String? currentImageUrl, {
    required VoidCallback onRemove,
  }) {
    if (newImage != null) {
      // Show newly selected image
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              newImage,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    } else if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
      // Show existing image from URL
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              currentImageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.directions_car,
                    size: 60,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
          // Add edit overlay
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.PRIMARY_COLOR,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 16),
            ),
          ),
        ],
      );
    } else {
      // Show placeholder
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add),
          Text('attach_image'.tr(), style: AppTheme.labelStyle),
        ],
      );
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: AppTheme.textFieldDecoration.copyWith(
            hintText: hintText ?? '',
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(
            hint,
            style: GoogleFonts.manrope(
              color: AppTheme.TEXT_COLOR,
              fontSize: 15,
            ),
          ),
          decoration: AppTheme.textFieldDecoration,
          items:
              items.map((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
          onChanged: onChanged,
          validator: validator,
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
      ],
    );
  }
}
