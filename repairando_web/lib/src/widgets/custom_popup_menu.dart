import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_web/src/features/home/presentation/controllers/workshop_setting_controller.dart';

class CustomPopupMenuWidget extends HookConsumerWidget {
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;

  const CustomPopupMenuWidget({
    super.key,

    this.onSettingsTap,
    this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(fetchWorkshopProfileControllerProvider);
    return profileState.when(
      loading: () => SizedBox(),
      error: (error, _) => Center(child: Text('${'error_prefix'.tr()}$error')),
      data: (profile) {
        return PopupMenuButton<String>(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // User Avatar
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE17142),
                    shape: BoxShape.circle,
                  ),
                  child:
                      profile.profileImageUrl != null
                          ? ClipOval(
                            child: Image.network(
                              profile.profileImageUrl!,
                              width: 30,
                              height: 30,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 28,
                                );
                              },
                            ),
                          )
                          : const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 28,
                          ),
                ),
                const SizedBox(width: 16),

                // User Name
                Text(
                  profile.companyName!,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),

                // Dropdown Icon
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ],
            ),
          ),
          itemBuilder:
              (BuildContext context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Settings Item
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                onSettingsTap?.call();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.settings_outlined,
                                      size: 24,
                                      color: Colors.grey[700],
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'settings'.tr(),
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Divider
                            Container(
                              height: 1,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              color: Colors.grey[200],
                            ),

                            // Logout Item
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                onLogoutTap?.call();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.logout_outlined,
                                      size: 24,
                                      color: Colors.grey[700],
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'logout'.tr(),
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
        );
      },
    );
  }
}
