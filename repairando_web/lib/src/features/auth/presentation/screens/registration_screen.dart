import 'package:flutter/material.dart';
import 'package:repairando_web/src/constants/app_images.dart';
import 'package:repairando_web/src/features/auth/domain/workshop_registration_model.dart';
import 'package:repairando_web/src/features/auth/presentation/controllers/registration_controller.dart';
import 'package:repairando_web/src/router/app_router.dart';
import 'package:repairando_web/src/widgets/primary_button.dart';
import 'package:repairando_web/src/theme/theme.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

class RegistrationScreen extends HookConsumerWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final formKey = GlobalKey<FormState>();
    final authState = ref.watch(registrationControllerProvider);
    final isLoading = authState is AsyncLoading;
    final isPasswordVisible = useState(false);
    final isConfirmPasswordVisible = useState(false);

    final registeredUser = useState<WorkshopRegistrationModel?>(null);

    final hasNavigated = useState(false);

    ref.listen<AsyncValue<void>>(registrationControllerProvider, (prev, next) {
      if (next is AsyncData &&
          registeredUser.value != null &&
          !hasNavigated.value) {
        hasNavigated.value = true;

        context.push(AppRoutes.otpVerification, extra: registeredUser.value);
        registeredUser.value = null;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('verification_sent'.tr())));
      }
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
            child: Form(
              key: formKey,
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
                            'register_title'.tr(),
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.bold,
                              fontSize: 31,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'email_label'.tr(),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: emailController,
                          decoration: AppTheme.textFieldDecoration.copyWith(
                            hintText: 'email_hint'.tr(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'email_required'.tr();
                            } else if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                            ).hasMatch(value)) {
                              return 'email_invalid'.tr();
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),
                        Text(
                          'password_label'.tr(),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible.value,
                          decoration: AppTheme.textFieldDecoration.copyWith(
                            hintText: 'password_hint'.tr(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible.value
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                isPasswordVisible.value =
                                    !isPasswordVisible.value;
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'password_required'.tr();
                            } else if (value.length < 6) {
                              return 'password_too_short'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'confirm_password_label'.tr(),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: !isConfirmPasswordVisible.value,
                          decoration: AppTheme.textFieldDecoration.copyWith(
                            hintText: 'password_hint'.tr(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isConfirmPasswordVisible.value
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                isConfirmPasswordVisible.value =
                                    !isConfirmPasswordVisible.value;
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'password_required'.tr();
                            } else if (value != passwordController.text) {
                              return 'confirm_password_mismatch'.tr();
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),
                        PrimaryButton(
                          text: isLoading ? null : 'register_button'.tr(),
                          onPressed:
                              isLoading
                                  ? null
                                  : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }

                                    final user = WorkshopRegistrationModel(
                                      userId: '',
                                      email: emailController.text.trim(),
                                    );

                                    registeredUser.value = user;

                                    await ref
                                        .read(
                                          registrationControllerProvider
                                              .notifier,
                                        )
                                        .register(
                                          email: user.email!,
                                          password:
                                              passwordController.text.trim(),
                                        );
                                  },
                          child:
                              isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : null,
                        ),

                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            context.pop();
                          },
                          child: Center(
                            child: RichText(
                              text: TextSpan(
                                text: 'have_account'.tr(),
                                style: TextStyle(
                                  color: Color(0xFF0A0D1C),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'login_text'.tr(),
                                    style: GoogleFonts.manrope(
                                      color: Color(0xFFFF5C00),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
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
      ),
    );
  }
}
