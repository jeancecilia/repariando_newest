import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/common/widgets/outlined_primary_button.dart';
import 'package:repairando_mobile/src/common/widgets/primary_button.dart';

void showDeleteAccountDialog({
  required BuildContext context,
  required Future<void> Function() onDelete,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      bool isLoading = false;

      return StatefulBuilder(
        builder:
            (context, setState) => Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      'delete_account_dialog_title'.tr(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child:
                              isLoading
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : PrimaryButton(
                                    text: 'delete'.tr(),
                                    onPressed: () async {
                                      setState(() => isLoading = true);
                                      try {
                                        await onDelete();
                                        if (context.mounted) {
                                          context.pop(); // close dialog
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'delete_account_dialog_failed'
                                                    .tr(),
                                              ),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (context.mounted) {
                                          setState(() => isLoading = false);
                                        }
                                      }
                                    },
                                  ),
                        ),
                        SizedBox(width: 20.w),
                        Expanded(
                          child: OutlinedPrimaryButton(
                            text: 'cancel'.tr(),
                            onPressed: () {
                              context.pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      );
    },
  );
}
