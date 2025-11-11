import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_mobile/src/features/auth/data/auth_repository.dart';

final registrationControllerProvider =
    StateNotifierProvider<RegistrationController, AsyncValue<void>>((ref) {
      final authRepository = ref.read(authRepositoryProvider);
      return RegistrationController(authRepository);
    });

class RegistrationController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  RegistrationController(this._authRepository) : super(const AsyncData(null));

  Future<void> register({
    required String name,
    required String surname,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await _authRepository.registration(
        name: name,
        surname: surname,
        email: email,
        password: password,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
