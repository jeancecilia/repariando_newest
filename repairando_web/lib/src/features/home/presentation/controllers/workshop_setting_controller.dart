import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_web/src/features/home/data/workshop_setting_repository.dart';
import 'package:repairando_web/src/features/home/domain/working_setting_model.dart';
import 'package:repairando_web/src/infra/custom_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final workshopProfileRepositoryProvider = Provider<WorkshopSettingRepository>(
  (ref) => WorkshopSettingRepository(Supabase.instance.client),
);

final fetchWorkshopProfileControllerProvider = StateNotifierProvider<
  FetchWorkshopProfileController,
  AsyncValue<WorkshopSettingModel>
>((ref) {
  final repository = ref.read(workshopProfileRepositoryProvider);
  return FetchWorkshopProfileController(repository);
});

final updateWorkshopProfileControllerProvider = StateNotifierProvider<
  UpdateWorkshopProfileController,
  AsyncValue<WorkshopSettingModel?>
>((ref) {
  final repository = ref.read(workshopProfileRepositoryProvider);
  return UpdateWorkshopProfileController(repository, ref);
});

class FetchWorkshopProfileController
    extends StateNotifier<AsyncValue<WorkshopSettingModel>> {
  final WorkshopSettingRepository _repository;

  FetchWorkshopProfileController(this._repository)
    : super(const AsyncLoading());

  Future<void> fetchProfile() async {
    try {
      state = const AsyncLoading();

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw CustomException("User not authenticated");
      }

      final profile = await _repository.fetchWorkshopProfile(userId);
      state = AsyncData(profile);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

class UpdateWorkshopProfileController
    extends StateNotifier<AsyncValue<WorkshopSettingModel?>> {
  final WorkshopSettingRepository _repository;
  final Ref _ref;

  UpdateWorkshopProfileController(this._repository, this._ref)
    : super(const AsyncData(null));

  Future<void> updateProfile(WorkshopUpdateModel updateModel) async {
    try {
      state = const AsyncLoading();

      final updatedProfile = await _repository.updateWorkshopProfile(
        updateModel,
      );
      state = AsyncData(updatedProfile);

      // Also update the fetch controller with the new data
      _ref
          .read(fetchWorkshopProfileControllerProvider.notifier)
          .state = AsyncData(updatedProfile);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void resetState() {
    state = const AsyncData(null);
  }
}
