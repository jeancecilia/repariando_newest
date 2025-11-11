import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_web/src/features/home/domain/workshop_opening_hour_model.dart';
import 'package:repairando_web/src/features/home/presentation/controllers/workshop_setting_controller.dart';

final workshopOpeningControllerProvider = StateNotifierProvider.autoDispose<
  WorkshopOpeningController,
  AsyncValue<List<WorkshopOpeningHour>>
>((ref) => WorkshopOpeningController(ref));

class WorkshopOpeningController
    extends StateNotifier<AsyncValue<List<WorkshopOpeningHour>>> {
  final Ref ref;

  WorkshopOpeningController(this.ref) : super(const AsyncValue.loading());

  Future<void> loadHours(String adminId) async {
    try {
      final repo = ref.read(workshopProfileRepositoryProvider);
      final hours = await repo.fetchOpeningHours(adminId);
      state = AsyncValue.data(hours);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveHours(
    String adminId,
    List<WorkshopOpeningHour> hours,
  ) async {
    try {
      state = const AsyncValue.loading();
      final repo = ref.read(workshopProfileRepositoryProvider);
      await repo.saveOpeningHours(adminId, hours);
      await loadHours(adminId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
