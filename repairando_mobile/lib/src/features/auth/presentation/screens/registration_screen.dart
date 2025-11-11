import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/common/widgets/circle_back_button.dart';
import 'package:repairando_mobile/src/common/widgets/primary_button.dart';
import 'package:repairando_mobile/src/features/auth/domain/customer_model.dart';
import 'package:repairando_mobile/src/features/auth/presentation/controllers/registration_controller.dart';
import 'package:repairando_mobile/src/router/app_router.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class RegistrationScreen extends HookConsumerWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final surnameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = GlobalKey<FormState>();

    final authState = ref.watch(registrationControllerProvider);
    final isLoading = authState is AsyncLoading;
    final isPasswordVisible = useState(false);

    final registeredUser = useState<CustomerModel?>(null);

    final hasNavigated = useState(false);

    ref.listen<AsyncValue<void>>(registrationControllerProvider, (prev, next) {
      if (next is AsyncData &&
          registeredUser.value != null &&
          !hasNavigated.value) {
        hasNavigated.value = true;

        context.push(AppRoutes.confirmOtp, extra: registeredUser.value);
        registeredUser.value = null;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('verification_email_sent'.tr())));
      }
    });

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
                Text('register_title'.tr(), style: AppTheme.headlineLarge),
                SizedBox(height: 20.h),
                Text('name_label'.tr(), style: AppTheme.labelStyle),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: nameController,
                  decoration: AppTheme.textFieldDecoration.copyWith(
                    hintText: 'name_hint'.tr(),
                  ),
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? 'name_required'.tr()
                              : null,
                ),
                SizedBox(height: 24.h),
                Text('surname_label'.tr(), style: AppTheme.labelStyle),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: surnameController,
                  decoration: AppTheme.textFieldDecoration.copyWith(
                    hintText: 'surname_hint'.tr(),
                  ),
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? 'surname_required'.tr()
                              : null,
                ),
                SizedBox(height: 24.h),
                Text('email_label'.tr(), style: AppTheme.labelStyle),
                SizedBox(height: 8.h),
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
                SizedBox(height: 24.h),
                Text('password_label'.tr(), style: AppTheme.labelStyle),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible.value,
                  textInputAction: TextInputAction.done,
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
                const Spacer(),
                PrimaryButton(
                  text: isLoading ? null : 'register_button'.tr(),
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            if (!formKey.currentState!.validate()) return;

                            final user = CustomerModel(
                              id: '',
                              name: nameController.text.trim(),
                              surname: surnameController.text.trim(),
                              email: emailController.text.trim(),
                              profileImage: '',
                            );

                            registeredUser.value = user;

                            await ref
                                .read(registrationControllerProvider.notifier)
                                .register(
                                  name: user.name,
                                  surname: user.surname,
                                  email: user.email,
                                  password: passwordController.text.trim(),
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
                const Spacer(),
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'already_have_account'.tr(),
                      style: const TextStyle(
                        color: Color(0xFF0A0D1C),
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'login_link'.tr(),
                          style: GoogleFonts.manrope(
                            color: const Color(0xFFFF5C00),
                            fontWeight: FontWeight.w700,
                          ),
                          recognizer:
                              TapGestureRecognizer()
                                ..onTap = () {
                                  context.pop();
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
