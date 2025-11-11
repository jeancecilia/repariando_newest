import 'package:flutter/material.dart';
import 'package:repairando_web/src/constants/app_images.dart';
import 'package:repairando_web/src/features/auth/presentation/controllers/login_controller.dart';
import 'package:repairando_web/src/infra/custom_exception.dart';
import 'package:repairando_web/src/router/app_router.dart';
import 'package:repairando_web/src/widgets/primary_button.dart';
import 'package:repairando_web/src/theme/theme.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final authState = ref.watch(loginControllerProvider);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isPasswordVisible = useState(false);

    // Listen to auth state changes
    ref.listen<AsyncValue<void>>(loginControllerProvider, (previous, current) {
      current.when(
        data: (_) {
          // Success - navigate to bottom nav
          if (context.mounted) {
            context.pushReplacement(AppRoutes.home);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('login_success'.tr()),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        error: (error, stackTrace) {
          // Handle error
          if (context.mounted) {
            String errorMessage = 'login_error'.tr();
            if (error is CustomException) {
              errorMessage = error.message;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        loading: () {},
      );
    });

    Future<void> handleLogin() async {
      // Validate form
      if (!formKey.currentState!.validate()) return;

      // Call login from AuthController
      await ref
          .read(loginControllerProvider.notifier)
          .login(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
    }

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
                            'login_title'.tr(),
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
                            ).hasMatch(value.trim())) {
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
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => handleLogin(),
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
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                context.go(AppRoutes.forgetPassword);
                              },
                              child: Text(
                                'forgot_password'.tr(),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Login Button
                        PrimaryButton(
                          text:
                              authState.isLoading ? null : 'login_button'.tr(),
                          onPressed: authState.isLoading ? null : handleLogin,
                          child:
                              authState.isLoading
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
                            context.go(AppRoutes.registration);
                          },
                          child: Center(
                            child: RichText(
                              text: TextSpan(
                                text: 'no_account'.tr(),
                                style: TextStyle(
                                  color: Color(0xFF0A0D1C),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'create_account'.tr(),
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
