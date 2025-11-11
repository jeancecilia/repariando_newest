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

class AddMyVehicleScreen extends HookConsumerWidget {
  const AddMyVehicleScreen({super.key});

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

    // Watch the vehicle controller state
    final vehicleState = ref.watch(vehicleControllerProvider);
    final vehicleController = ref.read(vehicleControllerProvider.notifier);

    // Watch for the selected vehicle image
    final vehicleImage = useState<File?>(null);

    // Listen to controller state changes for UI feedback
    ref.listen<AsyncValue<void>>(vehicleControllerProvider, (previous, next) {
      next.when(
        data: (_) {
          if (previous?.isLoading == true) {
            // Success - vehicle was added
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('vehicle_added_successfully'.tr()),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate back or clear form
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
          'my_vehicle_title'.tr(),
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
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('add_vehicle_images'.tr(), style: AppTheme.labelStyle),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final pickedImage =
                      await vehicleController.pickVehicleImage();
                  if (pickedImage != null) {
                    vehicleImage.value = pickedImage;
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
                      child:
                          vehicleImage.value != null
                              ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      vehicleImage.value!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        vehicleImage.value = null;
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add),
                                  Text(
                                    'attach_image'.tr(),
                                    style: AppTheme.labelStyle,
                                  ),
                                ],
                              ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30.h),

              _buildTextField(
                label: 'vehicle_name'.tr(),
                controller: vehicleNameController,
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'required'.tr() : null,
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
                  if (value == null || value.isEmpty) return 'required'.tr();
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
                        value == null ? 'select_mileage_validation'.tr() : null,
              ),

              SizedBox(height: 40.h),

              PrimaryButton(
                text:
                    vehicleState.isLoading ? 'saving'.tr() : 'save_button'.tr(),
                onPressed:
                    vehicleState.isLoading
                        ? null
                        : () async {
                          if (formKey.currentState!.validate()) {
                            await vehicleController.addVehicle(
                              vehicleName: vehicleNameController.text.trim(),
                              vin:
                                  vinController.text.trim().isEmpty
                                      ? null
                                      : vinController.text.trim(),
                              vehicleMake:
                                  vehicleMakeController.text.trim().isEmpty
                                      ? null
                                      : vehicleMakeController.text.trim(),
                              vehicleModel:
                                  vehicleModelController.text.trim().isEmpty
                                      ? null
                                      : vehicleModelController.text.trim(),
                              vehicleYear:
                                  selectedYear.text.trim().isEmpty
                                      ? null
                                      : selectedYear.text.trim(),
                              engineType: selectedEngineType.value,
                              mileage: selectedMileaAge.value,
                            );
                          }
                        },
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
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
