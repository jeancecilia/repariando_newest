import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_web/src/features/home/domain/appointment_model.dart';
import 'package:repairando_web/src/features/home/presentation/controllers/appointment_controller.dart';
import 'package:repairando_web/src/theme/theme.dart';
import 'package:repairando_web/src/widgets/sent_offer_dialog.dart';

class MakeOfferDialog extends HookConsumerWidget {
  final AppointmentModel appointment;

  const MakeOfferDialog({super.key, required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceController = useTextEditingController();
    final workUnitsController = useTextEditingController();

    final appointmentRepository = ref.read(appointmentRepositoryProvider);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'make_offer_title'.tr(),
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('enter_price_label'.tr(), style: _labelStyle()),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: priceController,
                    hint: 'price_hint'.tr(),
                  ),

                  const SizedBox(height: 24),

                  Text('work_units_label'.tr(), style: _labelStyle()),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: workUnitsController,
                    hint: 'work_units_hint'.tr(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: _outlinedButtonStyle(),
                    child: Text(
                      'cancel_button'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.PRIMARY_COLOR,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final price =
                          double.tryParse(priceController.text.trim()) ?? 0.0;
                      final workUnits = workUnitsController.text.trim();

                      if (price <= 0 || workUnits.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('invalid_input_error'.tr()),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      final success = await appointmentRepository.sendOffer(
                        appointmentId: appointment.id,
                        price: price,
                        neededWorkUnit: workUnits,
                      );

                      if (success) {
                        context.pop();
                        showDialog(
                          context: context,
                          builder: (_) => const OfferSentDialog(),
                        );
                      }
                    },
                    style: _elevatedButtonStyle(),
                    child: Text(
                      'send_offer_button'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: hint == 'price_hint'.tr() 
          ? const TextInputType.numberWithOptions(decimal: true) 
          : TextInputType.text,
      inputFormatters: hint == 'price_hint'.tr() 
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : null,
      decoration: AppTheme.textFieldDecoration.copyWith(hintText: hint),
      style: const TextStyle(fontSize: 16, color: Colors.black87),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  ButtonStyle _outlinedButtonStyle() => ElevatedButton.styleFrom(
    foregroundColor: AppTheme.PRIMARY_COLOR,
    backgroundColor: Colors.white,
    side: const BorderSide(color: AppTheme.PRIMARY_COLOR),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    minimumSize: const Size(80, 32),
  );

  ButtonStyle _elevatedButtonStyle() => ElevatedButton.styleFrom(
    backgroundColor: AppTheme.PRIMARY_COLOR,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    minimumSize: const Size(80, 32),
  );
}
