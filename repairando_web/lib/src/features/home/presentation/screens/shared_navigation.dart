import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_web/src/constants/app_images.dart';
import 'package:repairando_web/src/features/home/presentation/controllers/logout_controller.dart';
import 'package:repairando_web/src/router/app_router.dart';
import 'package:repairando_web/src/theme/theme.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_web/src/widgets/custom_popup_menu.dart';

class SharedNavigation extends HookConsumerWidget {
  const SharedNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current route to determine active tab
    final currentRoute = GoRouterState.of(context).uri.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: AppTheme.LITE_PRIMARY_COLOR,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              context.go(AppRoutes.home);
            },
            child: Image.asset(AppImages.APP_LOGO, height: 40),
          ),

          const Spacer(),

          Row(
            children: [
              _buildNavTab(
                context,
                'upcoming_appointments'.tr(),
                currentRoute == AppRoutes.upcomingAppointment,
                () => context.go(AppRoutes.upcomingAppointment),
              ),

              const SizedBox(width: 24),
              _buildNavTab(
                context,
                'service_management'.tr(),
                currentRoute == AppRoutes.serviceManagement,
                () => context.go(AppRoutes.serviceManagement),
              ),
              const SizedBox(width: 24),
              _buildNavTab(
                context,
                'messages'.tr(),
                currentRoute == AppRoutes.messages,
                () => context.go(AppRoutes.messages),
              ),
            ],
          ),

          const Spacer(),

          CustomPopupMenuWidget(
            onSettingsTap: () {
              context.go(AppRoutes.workshopSetting);
            },
            onLogoutTap: () async {
              await _handleLogout(context, ref);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavTab(
    BuildContext context,
    String title,
    bool isActive,
    VoidCallback onTap,
  ) {
    return HookBuilder(
      builder: (context) {
        final isHovered = useState(false);

        return InkWell(
          onTap: onTap,
          onHover: (hovering) => isHovered.value = hovering,
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

            child: Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight:
                    isActive || isHovered.value
                        ? FontWeight.w600
                        : FontWeight.normal,
                color:
                    isActive
                        ? AppTheme.PRIMARY_COLOR
                        : isHovered.value
                        ? Colors.black54
                        : Colors.grey[600],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(logoutControllerProvider.notifier);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await controller.logout();
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    final logoutState = ref.read(logoutControllerProvider);
    logoutState.whenOrNull(
      error: (err, _) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err.toString())));
      },
      data: (_) {
        context.go(AppRoutes.login);
      },
    );
  }
}
