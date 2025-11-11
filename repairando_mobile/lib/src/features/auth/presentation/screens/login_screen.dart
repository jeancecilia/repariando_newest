import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/features/auth/presentation/controllers/login_controller.dart';
import 'package:repairando_mobile/src/infra/custom_exception.dart';
import 'package:repairando_mobile/src/router/app_router.dart';
import 'package:repairando_mobile/src/common/widgets/circle_back_button.dart';
import 'package:repairando_mobile/src/common/widgets/primary_button.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final authState = ref.watch(loginControllerProvider);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isChecked = useState(false);
    final isPasswordVisible = useState(false);

    // Listen to auth state changes
    ref.listen<AsyncValue<void>>(loginControllerProvider, (previous, current) {
      current.when(
        data: (_) {
          // Success - navigate to bottom nav
          if (context.mounted) {
            context.pushReplacement(AppRoutes.bottomNav);
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
            String errorMessage = 'login_failed'.tr();
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

      // Ensure terms checkbox is checked
      if (!isChecked.value) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('terms_agreement_required'.tr()),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24.h),
                const CircleBackButton(),
                SizedBox(height: 20.h),
                Text('login_title'.tr(), style: AppTheme.headlineLarge),
                SizedBox(height: 20.h),

                // Email Field
                Text('email_label'.tr(), style: AppTheme.labelStyle),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
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
                SizedBox(height: 24.h),

                // Password Field Header
                Text('password_label'.tr(), style: AppTheme.labelStyle),
                SizedBox(height: 8.h),

                // Password Field
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
                        isPasswordVisible.value = !isPasswordVisible.value;
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'password_required'.tr();
                    } else if (value.length < 6) {
                      return 'password_min_length'.tr();
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Terms and Conditions Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: isChecked.value,
                      onChanged: (value) {
                        isChecked.value = value ?? false;
                      },
                      activeColor: const Color(0xFFFF5C00),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          isChecked.value = !isChecked.value;
                        },
                        child: Text(
                          'terms_checkbox'.tr(),
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Login Button
                PrimaryButton(
                  text: authState.isLoading ? null : 'login_button'.tr(),
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

                SizedBox(height: 24.h),

                // Create Account Link
                GestureDetector(
                  onTap: () => context.push(AppRoutes.registration),
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        text: 'new_user_text'.tr(),
                        style: const TextStyle(
                          color: Color(0xFF0A0D1C),
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: 'create_account_text'.tr(),
                            style: GoogleFonts.manrope(
                              color: const Color(0xFFFF5C00),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
