import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_web/src/features/auth/data/auth_repository.dart';
import 'package:repairando_web/src/features/auth/domain/workshop_registration_model.dart';

final otpVerificationControllerProvider =
    StateNotifierProvider<OtpVerificationController, AsyncValue<void>>((ref) {
      final authRepository = ref.read(authRepositoryProvider);
      return OtpVerificationController(authRepository);
    });

class OtpVerificationController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  OtpVerificationController(this._authRepository)
    : super(const AsyncData(null));

  Future<void> verifyOtp({
    required String otp,
    required WorkshopRegistrationModel user,
  }) async {
    state = const AsyncLoading();
    try {
      await _authRepository.verifyOtpAndStoreUser(otp: otp, user: user);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
