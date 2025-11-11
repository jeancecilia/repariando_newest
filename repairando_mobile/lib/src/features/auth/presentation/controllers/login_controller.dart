import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_mobile/src/features/auth/data/auth_repository.dart';

final loginControllerProvider =
    StateNotifierProvider<LoginController, AsyncValue<void>>((ref) {
      final authRepository = ref.read(authRepositoryProvider);
      return LoginController(authRepository);
    });

class LoginController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  LoginController(this._authRepository) : super(const AsyncData(null));

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      await _authRepository.login(email: email, password: password);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
