// lib/src/features/services/presentation/controllers/service_controller.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_web/src/features/home/data/service_repository.dart';
import 'package:repairando_web/src/features/home/domain/service_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>(
  (ref) => ServiceRepository(Supabase.instance.client),
);

final fetchServicesControllerProvider = StateNotifierProvider<
  FetchServicesController,
  AsyncValue<List<ServiceWithAvailability>>
>((ref) {
  final repository = ref.read(serviceRepositoryProvider);
  return FetchServicesController(repository);
});

final updateServiceControllerProvider =
    StateNotifierProvider<UpdateServiceController, AsyncValue<bool>>((ref) {
      final repository = ref.read(serviceRepositoryProvider);
      return UpdateServiceController(repository, ref);
    });

class FetchServicesController
    extends StateNotifier<AsyncValue<List<ServiceWithAvailability>>> {
  final ServiceRepository _repository;

  FetchServicesController(this._repository) : super(const AsyncLoading());

  Future<void> fetchServices() async {
    try {
      state = const AsyncLoading();
      final services = await _repository.fetchServicesWithAvailability();
      state = AsyncData(services);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void updateLocalService(
    String serviceId,
    bool isAvailable,
    double price,
    String duration,
  ) {
    state.whenData((services) {
      final updatedServices =
          services.map((serviceWithAvailability) {
            if (serviceWithAvailability.service.id == serviceId) {
              final updatedAdminService =
                  serviceWithAvailability.adminService?.copyWith(
                    isAvailable: isAvailable,
                    price: price,
                    durationMinutes: duration,
                  ) ??
                  AdminServiceModel(
                    id: 0, // Will be set by the server
                    createdAt: DateTime.now(),
                    adminId: '', // Will be set by the server
                    serviceId: serviceId,
                    isAvailable: isAvailable,
                    price: price,
                    durationMinutes: duration,
                  );

              return serviceWithAvailability.copyWith(
                adminService: updatedAdminService,
              );
            }
            return serviceWithAvailability;
          }).toList();

      state = AsyncData(updatedServices);
    });
  }
}

class UpdateServiceController extends StateNotifier<AsyncValue<bool>> {
  final ServiceRepository _repository;
  final Ref _ref;

  UpdateServiceController(this._repository, this._ref)
    : super(const AsyncData(false));

  Future<void> updateService(UpdateServiceRequest request) async {
    try {
      state = const AsyncLoading();

      await _repository.updateServiceAvailability(request);

      // Update local state
      _ref
          .read(fetchServicesControllerProvider.notifier)
          .updateLocalService(
            request.serviceId,
            request.isAvailable,
            request.price,
            request.durationMinutes,
          );

      state = const AsyncData(true);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateMultipleServices(
    List<UpdateServiceRequest> requests,
  ) async {
    try {
      state = const AsyncLoading();

      // Update all services
      for (final request in requests) {
        await _repository.updateServiceAvailability(request);

        // Update local state for each service
        _ref
            .read(fetchServicesControllerProvider.notifier)
            .updateLocalService(
              request.serviceId,
              request.isAvailable,
              request.price,
              request.durationMinutes,
            );
      }

      state = const AsyncData(true);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void resetState() {
    state = const AsyncData(false);
  }
}
