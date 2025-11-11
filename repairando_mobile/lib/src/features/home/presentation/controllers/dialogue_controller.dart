import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_mobile/src/features/home/presentation/screens/configure_vehicle_dialog.dart';

final dialogShownProvider = StateProvider<bool>((ref) => false);

final dialogHandlerProvider = Provider((ref) {
  return DialogHandler(ref);
});

class DialogHandler {
  final Ref ref;
  DialogHandler(this.ref);

  Future<void> handleInitialDialog(BuildContext context) async {
    final shown = ref.read(dialogShownProvider);
    if (!shown) {
      showVehicleRequiredDialog(context);
      ref.read(dialogShownProvider.notifier).state = true;
    }
  }
}
