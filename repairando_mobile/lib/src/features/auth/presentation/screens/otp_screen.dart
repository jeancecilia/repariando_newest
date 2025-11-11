import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/common/widgets/circle_back_button.dart';
import 'package:repairando_mobile/src/common/widgets/primary_button.dart';
import 'package:repairando_mobile/src/features/auth/domain/customer_model.dart';
import 'package:repairando_mobile/src/features/auth/presentation/controllers/otp_verification_controller.dart';
import 'package:repairando_mobile/src/router/app_router.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class ConfirmOtpScreen extends HookConsumerWidget {
  final CustomerModel user;
  const ConfirmOtpScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otpInput = useState('');
    final controllerState = ref.watch(otpVerificationControllerProvider);

    ref.listen(otpVerificationControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.toString())));
        },
        data: (_) {
          context.go(AppRoutes.bottomNav);
        },
      );
    });

    return Scaffold(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.h),
              const CircleBackButton(),
              SizedBox(height: 16.h),
              Text('confirm_otp_title'.tr(), style: AppTheme.headlineLarge),
              SizedBox(height: 16.h),
              Text('enter_6_digit_code'.tr(), style: AppTheme.labelStyle),
              SizedBox(height: 16.h),

              // OTP Input
              Pinput(
                length: 6,
                defaultPinTheme: AppTheme.defaultPinTheme,
                separatorBuilder: (index) => const SizedBox(width: 8),
                hapticFeedbackType: HapticFeedbackType.lightImpact,
                onCompleted: (pin) => otpInput.value = pin,
                onChanged: (value) => otpInput.value = value,
                cursor: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 9),
                      width: 22,
                      height: 1,
                      color: AppTheme.LITE_PRIMARY_COLOR,
                    ),
                  ],
                ),
                focusedPinTheme: AppTheme.defaultPinTheme.copyWith(
                  decoration: AppTheme.defaultPinTheme.decoration!.copyWith(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.LITE_PRIMARY_COLOR),
                  ),
                ),
                submittedPinTheme: AppTheme.defaultPinTheme.copyWith(
                  decoration: AppTheme.defaultPinTheme.decoration!.copyWith(
                    color: AppTheme.FILL_COLOR,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.LITE_PRIMARY_COLOR),
                  ),
                ),
                errorPinTheme: AppTheme.defaultPinTheme.copyWith(
                  decoration: AppTheme.defaultPinTheme.decoration!.copyWith(
                    color: AppTheme.FILL_COLOR,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.LITE_PRIMARY_COLOR),
                  ),
                ),
              ),

              SizedBox(height: 15.h),
              Text(
                'otp_sent_message'.tr(),
                style: GoogleFonts.manrope(
                  color: const Color(0xFFFF5C00),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 30.h),

              // Submit Button
              PrimaryButton(
                text: controllerState.maybeWhen(
                  loading: () => null,
                  orElse: () => 'verify_complete_profile'.tr(),
                ),
                onPressed:
                    controllerState is AsyncLoading
                        ? null
                        : () async {
                          if (otpInput.value.length != 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('invalid_otp_length'.tr()),
                              ),
                            );
                            return;
                          }

                          await ref
                              .read(otpVerificationControllerProvider.notifier)
                              .verifyOtp(otp: otpInput.value, user: user);
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

              SizedBox(height: 16.h),
              RichText(
                text: TextSpan(
                  text: 'not_received_yet'.tr(),
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF0A0D1C),
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: 'resend'.tr(),
                      style: GoogleFonts.manrope(
                        color: const Color(0xFFFF5C00),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
