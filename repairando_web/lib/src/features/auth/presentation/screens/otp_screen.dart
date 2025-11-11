import 'package:flutter/material.dart';
import 'package:repairando_web/src/constants/app_images.dart';
import 'package:repairando_web/src/features/auth/domain/workshop_registration_model.dart';
import 'package:repairando_web/src/features/auth/presentation/controllers/otp_verification_controller.dart';
import 'package:repairando_web/src/router/app_router.dart';
import 'package:repairando_web/src/widgets/primary_button.dart';
import 'package:repairando_web/src/theme/theme.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

class OtpScreen extends HookConsumerWidget {
  final WorkshopRegistrationModel user;
  const OtpScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otpController = useTextEditingController();
    final controllerState = ref.watch(otpVerificationControllerProvider);

    ref.listen(otpVerificationControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.toString())));
        },
        data: (_) {
          context.go(AppRoutes.workshopProfileSetup);
        },
      );
    });

    return Scaffold(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      appBar: AppBar(
        backgroundColor: AppTheme.LITE_PRIMARY_COLOR,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(AppImages.APP_LOGO, height: 40),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  width: 500,
                  decoration: BoxDecoration(
                    color: AppTheme.LITE_PRIMARY_COLOR,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'otp_title'.tr(),
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 31,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'otp_description'.tr(),
                          style: GoogleFonts.manrope(
                            color: Color(0xFFFF5C00),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'otp_label'.tr(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(controller: otpController),

                      const SizedBox(height: 24),
                      // Submit Button
                      PrimaryButton(
                        text: controllerState.maybeWhen(
                          loading: () => null,
                          orElse: () => 'otp_submit'.tr(),
                        ),
                        onPressed:
                            controllerState is AsyncLoading
                                ? null
                                : () async {
                                  if (otpController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('otp_error_empty'.tr()),
                                      ),
                                    );
                                    return;
                                  }

                                  await ref
                                      .read(
                                        otpVerificationControllerProvider
                                            .notifier,
                                      )
                                      .verifyOtp(
                                        otp: otpController.text,
                                        user: user,
                                      );
                                },
                        child: controllerState.maybeWhen(
                          loading:
                              () => const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                          orElse: () => null,
                        ),
                      ),

                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          context.pop();
                        },
                        child: Center(
                          child: Text(
                            'go_back_to_login'.tr(),
                            style: TextStyle(
                              color: Color(0xFF0A0D1C),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
