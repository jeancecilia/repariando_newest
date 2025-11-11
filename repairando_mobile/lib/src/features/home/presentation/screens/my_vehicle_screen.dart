import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/constants/app_constants.dart';
import 'package:repairando_mobile/src/constants/app_images.dart';
import 'package:repairando_mobile/src/router/app_router.dart';
import 'package:repairando_mobile/src/common/widgets/circle_back_button.dart';
import 'package:repairando_mobile/src/common/widgets/primary_button.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class MyVehicleScreen extends HookConsumerWidget {
  const MyVehicleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleNameController = useTextEditingController(
      text: 'Toyota Corolla 2018',
    );
    final vinController = useTextEditingController();
    final vehicleMakeController = useTextEditingController();
    final vehicleModelController = useTextEditingController();
    final selectedYear = useState<String?>(null);
    final selectedEngineType = useState<String?>(null);
    final selectedMileaAge = useState<String?>(null);

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('add_vehicle_images'.tr(), style: AppTheme.labelStyle),
            const SizedBox(height: 16),

            // Vehicle Image Container
            Image.asset(AppImages.ATTACH_IMAGE),

            SizedBox(height: 30.h),

            // Vehicle Name Field
            _buildTextField(
              label: 'vehicle_name'.tr(),
              controller: vehicleNameController,
            ),

            SizedBox(height: 20.h),

            // VIN Field
            _buildTextField(
              label: 'vin_label'.tr(),
              controller: vinController,
              hintText: 'vin_hint'.tr(),
            ),

            SizedBox(height: 20.h),

            // Vehicle Make Field
            _buildTextField(
              label: 'vehicle_make'.tr(),
              controller: vehicleMakeController,
              hintText: 'vehicle_make_hint'.tr(),
            ),

            SizedBox(height: 20.h),

            // Vehicle Model Field
            _buildTextField(
              label: 'vehicle_model'.tr(),
              controller: vehicleModelController,
              hintText: 'vehicle_model_hint'.tr(),
            ),

            SizedBox(height: 20.h),

            // Year Dropdown
            _buildDropdownField(
              label: 'year_of_manufacture'.tr(),
              value: selectedYear.value,
              hint: 'year_of_manufacture_hint'.tr(),
              items: AppConstants.YEARS,
              onChanged: (value) => selectedYear.value = value,
            ),

            SizedBox(height: 20.h),

            // Engine Type Dropdown
            _buildDropdownField(
              label: 'engine_type'.tr(),
              value: selectedEngineType.value,
              hint: 'engine_type_hint'.tr(),
              items: AppConstants.ENGINE_TYPES,
              onChanged: (value) => selectedEngineType.value = value,
            ),
            SizedBox(height: 20.h),

            // Engine Type Dropdown
            _buildDropdownField(
              label: 'mileage'.tr(),
              value: selectedMileaAge.value,
              hint: 'mileage_hint'.tr(),
              items: AppConstants.MILEAGE,
              onChanged: (value) => selectedMileaAge.value = value,
            ),

            SizedBox(height: 40.h),

            PrimaryButton(text: 'save_button'.tr(), onPressed: () {}),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
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
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE85A3D)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items:
              items.map((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),

          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
      ],
    );
  }
}
