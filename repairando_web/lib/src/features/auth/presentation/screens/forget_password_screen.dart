import 'package:flutter/material.dart';
import 'package:repairando_web/src/constants/app_images.dart';
import 'package:repairando_web/src/widgets/primary_button.dart';
import 'package:repairando_web/src/theme/theme.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

final supabase = Supabase.instance.client;

class ForgetPasswordScreen extends HookConsumerWidget {
  const ForgetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();

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
                          'forgot_password_title'.tr(),
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 31,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'forgot_password_description'.tr(),
                          style: GoogleFonts.manrope(
                            color: Color(0xFFFF5C00),
                            fontWeight: FontWeight.w700,
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
                      TextField(
                        controller: emailController,
                        decoration: AppTheme.textFieldDecoration.copyWith(
                          hintText: 'email_hint'.tr(),
                        ),
                      ),

                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'continue_button'.tr(),
                        onPressed: () async {
                          try {
                            await supabase.auth.resetPasswordForEmail(
                              emailController.text.trim(),
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('reset_success'.tr())),
                            );
                          } on AuthException catch (e) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(e.message)));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('reset_error'.tr())),
                            );
                          }
                        },
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
