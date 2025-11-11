import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_mobile/src/features/auth/data/auth_repository.dart';

final logoutControllerProvider =
    StateNotifierProvider<LogoutController, AsyncValue<void>>((ref) {
      final authRepository = ref.read(authRepositoryProvider);
      return LogoutController(authRepository);
    });

class LogoutController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  LogoutController(this._authRepository) : super(const AsyncData(null));

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await _authRepository.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
