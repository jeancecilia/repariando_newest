import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_web/src/features/auth/data/auth_repository.dart';
import 'package:repairando_web/src/features/auth/domain/workshop_registration_model.dart';

final workshopProfileControllerProvider =
    StateNotifierProvider<WorkshopProfileController, AsyncValue<void>>((ref) {
      final authRepository = ref.read(authRepositoryProvider);
      return WorkshopProfileController(authRepository);
    });

class WorkshopProfileController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  WorkshopProfileController(this._authRepository)
    : super(const AsyncData(null));

  Future<void> completeWorkshopProfile(WorkshopRegistrationModel user) async {
    state = const AsyncLoading();
    try {
      await _authRepository.completeWorkshopProfile(user);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
