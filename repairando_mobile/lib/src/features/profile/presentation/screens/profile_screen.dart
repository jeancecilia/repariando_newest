import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/common/widgets/profile_shimmer.dart';
import 'package:repairando_mobile/src/constants/app_images.dart';
import 'package:repairando_mobile/src/features/profile/presentation/controllers/logout_controller.dart';
import 'package:repairando_mobile/src/features/profile/presentation/controllers/profile_controller.dart';
import 'package:repairando_mobile/src/features/profile/presentation/screens/delete_account_dialog.dart';
import 'package:repairando_mobile/src/router/app_router.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'my_profile'.tr(),
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.TEXT_COLOR,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.push(AppRoutes.notification);
                    },
                    child: Image.asset(
                      AppImages.NOTIFICATION_ICON,
                      height: 30.h,
                    ),
                  ),
                ],
              ),
            ),
            profileState.when(
              loading: () => const ProfileShimmer(),
              error:
                  (err, stack) => Center(
                    child: Text('${'error_colon'.tr()}${err.toString()}'),
                  ),
              data: (customer) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
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
                                  customer!.profileImage != ''
                                      ? Image.network(
                                        customer.profileImage!,
                                        width: 120.w,
                                        height: 120.h,
                                        fit: BoxFit.cover,
                                      )
                                      : Image.network(
                                        'https://developers.elementor.com/docs/assets/img/elementor-placeholder-image.png',
                                        width: 120.w,
                                        height: 120.h,
                                        fit: BoxFit.cover,
                                      ),
                            ),
                          ),
                          customer.profileImage != ''
                              ? Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(
                                          profileControllerProvider.notifier,
                                        )
                                        .deleteProfileImage();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.redAccent,
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              )
                              : SizedBox(),
                        ],
                      ),

                      SizedBox(height: 10.h),

                      Text(
                        customer.name,
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.TEXT_COLOR,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customer.email,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: AppTheme.TEXT_COLOR,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.PROFILE_BACKGROUND_COLOR,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      image: AppImages.OUTLINE_PROFILE_IMAGE,
                      title: 'my_profile'.tr(),
                      onTap: () {
                        context.push(AppRoutes.editProfile);
                      },
                    ),
                    _buildMenuItem(
                      image: AppImages.VEHICLE,
                      title: 'my_vehicles'.tr(),
                      onTap: () {
                        context.push(AppRoutes.viewVehicleList);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.PROFILE_BACKGROUND_COLOR,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      image: AppImages.DOCUMENT,
                      title: 'terms_conditions'.tr(),
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      image: AppImages.PRIVACY,
                      title: 'privacy_policy'.tr(),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.PROFILE_BACKGROUND_COLOR,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildMenuItem(
                  image: AppImages.DELETE,
                  title: 'delete_account'.tr(),
                  showArrow: false,
                  onTap: () {
                    showDeleteAccountDialog(
                      context: context,
                      onDelete: () async {
                        await ref
                            .read(profileControllerProvider.notifier)
                            .deleteAccount();
                        // Optionally, navigate away or log out
                        context.go(AppRoutes.login);
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.PROFILE_BACKGROUND_COLOR,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      image: AppImages.LOGOUT,
                      title: 'logout'.tr(),
                      showArrow: false,
                      onTap: () async {
                        final controller = ref.read(
                          logoutControllerProvider.notifier,
                        );

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder:
                              (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                        );

                        await controller.logout();
                        Navigator.of(context).pop();

                        final logoutState = ref.read(logoutControllerProvider);
                        logoutState.whenOrNull(
                          error: (err, _) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(err.toString())),
                            );
                          },
                          data: (_) {
                            context.go(AppRoutes.login);
                          },
                        );
                      },
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

  Widget _buildMenuItem({
    required String image,
    required String title,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Image.asset(image, height: 25.h),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),

            if (showArrow) const Icon(Icons.arrow_forward, size: 25),
          ],
        ),
      ),
    );
  }
}
