import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/constants/app_images.dart';
import 'package:repairando_mobile/src/common/widgets/primary_button.dart';
import 'package:repairando_mobile/src/router/app_router.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class WelcomeScreen extends HookConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Image.asset(
                    AppImages.MAINTENANCE_TEAM,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    'welcome_title'.tr(),
                    textAlign: TextAlign.center,
                    style: AppTheme.headlineLarge,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'get_started_button'.tr(),
                    onPressed: () {
                      context.push(AppRoutes.login);
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
