import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/common/widgets/circle_back_button.dart';
import 'package:repairando_mobile/src/common/widgets/primary_button.dart';
import 'package:repairando_mobile/src/features/profile/presentation/controllers/profile_controller.dart';
import 'package:repairando_mobile/src/theme/theme.dart';
import 'package:shimmer/shimmer.dart';

class EditProfileScreen extends HookConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);
    final selectedImage = useState<File?>(null);
    final nameController = TextEditingController();
    final surnameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(30.w),
        child: PrimaryButton(
          text: 'update'.tr(),
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;

            final name = nameController.text.trim();
            final surname = surnameController.text.trim();

            await controller.updateProfile(name: name, surname: surname);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('profile_updated'.tr())));
          },
        ),
      ),
      appBar: AppBar(
        backgroundColor: AppTheme.BACKGROUND_COLOR,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleBackButton(),
        ),
        centerTitle: true,
        title: Text(
          'my_profile'.tr(),
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.TEXT_COLOR,
          ),
        ),
      ),
      body: SafeArea(
        child: profileState.when(
          loading: () => _buildShimmer(),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (profile) {
            nameController.text = profile!.name;
            surnameController.text = profile.surname;

            return Form(
              key: formKey,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFF6B35),
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child:
                                    selectedImage.value != null
                                        ? Image.file(
                                          selectedImage.value!,
                                          width: 120.w,
                                          height: 120.h,
                                          fit: BoxFit.cover,
                                        )
                                        : Image.network(
                                          profile.profileImage ??
                                              'https://developers.elementor.com/docs/assets/img/elementor-placeholder-image.png',
                                          width: 120.w,
                                          height: 120.h,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => Container(
                                                width: 120.w,
                                                height: 120.h,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                        ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: () async {
                                  final file =
                                      await controller
                                          .pickProfileImage(); // Ensure it returns File?
                                  if (file != null) {
                                    selectedImage.value = file;
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10.h),
                              Text(
                                'name_label'.tr(),
                                style: AppTheme.labelStyle,
                              ),
                              SizedBox(height: 8.h),
                              TextFormField(
                                controller: nameController,
                                decoration: AppTheme.textFieldDecoration
                                    .copyWith(hintText: 'full_name_hint'.tr()),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'name_validation'.tr();
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 24.h),
                              Text(
                                'surname_label'.tr(),
                                style: AppTheme.labelStyle,
                              ),
                              SizedBox(height: 8.h),
                              TextFormField(
                                controller: surnameController,
                                decoration: AppTheme.textFieldDecoration
                                    .copyWith(hintText: 'surname_hint'.tr()),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'surname_validation'.tr();
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: CircleAvatar(radius: 60.r),
          ),
          SizedBox(height: 24.h),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 20.h,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16.h),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 20.h,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
