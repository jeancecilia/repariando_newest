import 'package:flutter/material.dart';
import 'package:repairando_web/src/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class OutlinedPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const OutlinedPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: const BorderSide(color: AppTheme.PRIMARY_COLOR, width: 2),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.PRIMARY_COLOR,
          ),
        ),
      ),
    );
  }
}
