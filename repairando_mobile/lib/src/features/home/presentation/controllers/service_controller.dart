// lib/src/features/workshop/controllers/service_controller.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_mobile/src/features/home/data/service_repository.dart';
import 'package:repairando_mobile/src/features/home/domain/service_model.dart';
import 'package:repairando_mobile/src/features/home/domain/workshop_opening_hour_model.dart';

// Provider for workshop services based on admin ID
final workshopServicesProvider = StateNotifierProvider.family<
  WorkshopServicesController,
  AsyncValue<List<ServiceModel>>,
  String
>((ref, adminId) {
  return WorkshopServicesController(ref, adminId);
});

// Provider for workshop opening hours
final workshopOpeningHoursProvider =
    FutureProvider.family<List<WorkshopOpeningHours>, String>((
      ref,
      adminId,
    ) async {
      final repository = ref.read(serviceRepositoryProvider);
      return repository.fetchWorkshopOpeningHours(adminId);
    });

// Provider for cached workshop opening hours (with manual refresh capability)
final cachedWorkshopOpeningHoursProvider = StateNotifierProvider.family<
  WorkshopOpeningHoursController,
  AsyncValue<List<WorkshopOpeningHours>>,
  String
>((ref, adminId) {
  return WorkshopOpeningHoursController(ref, adminId);
});

class WorkshopServicesController
    extends StateNotifier<AsyncValue<List<ServiceModel>>> {
  final Ref ref;
  final String adminId;

  WorkshopServicesController(this.ref, this.adminId)
    : super(const AsyncLoading()) {
    fetchWorkshopServices();
  }

  Future<void> fetchWorkshopServices() async {
    try {
      state = const AsyncLoading();
      final repository = ref.read(serviceRepositoryProvider);
      final services = await repository.fetchWorkshopServices(adminId);
      state = AsyncValue.data(services);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refreshServices() async {
    await fetchWorkshopServices();
  }

  Future<void> updateServiceAvailability(
    int serviceId,
    bool isAvailable,
  ) async {
    try {
      final repository = ref.read(serviceRepositoryProvider);
      await repository.updateServiceAvailability(
        serviceId: serviceId,
        isAvailable: isAvailable,
      );

      // Update local state
      state.whenData((services) {
        final updatedServices =
            services.map((service) {
              if (service.id == serviceId) {
                return ServiceModel(
                  id: service.id,
                  adminId: service.adminId,
                  serviceId: service.serviceId,
                  isAvailable: isAvailable,
                  price: service.price,
                  durationMinutes: service.durationMinutes,
                  createdAt: service.createdAt,
                  serviceName: service.serviceName,
                  description: service.description,
                  category: service.category,
                );
              }
              return service;
            }).toList();
        state = AsyncValue.data(updatedServices);
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class WorkshopOpeningHoursController
    extends StateNotifier<AsyncValue<List<WorkshopOpeningHours>>> {
  final Ref ref;
  final String adminId;

  WorkshopOpeningHoursController(this.ref, this.adminId)
    : super(const AsyncLoading()) {
    fetchOpeningHours();
  }

  Future<void> fetchOpeningHours() async {
    try {
      state = const AsyncLoading();
      final repository = ref.read(serviceRepositoryProvider);
      final openingHours = await repository.fetchWorkshopOpeningHours(adminId);
      state = AsyncValue.data(openingHours);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refreshOpeningHours() async {
    await fetchOpeningHours();
  }

  Future<void> updateOpeningHours({
    required String dayOfWeek,
    required bool isOpen,
    String? openTime,
    String? closeTime,
    String? breakStart,
    String? breakEnd,
  }) async {
    try {
      final repository = ref.read(serviceRepositoryProvider);
      await repository.updateWorkshopOpeningHours(
        adminId: adminId,
        dayOfWeek: dayOfWeek,
        isOpen: isOpen,
        openTime: openTime,
        closeTime: closeTime,
        breakStart: breakStart,
        breakEnd: breakEnd,
      );

      // Refresh the data after update
      await fetchOpeningHours();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateBulkOpeningHours(
    List<WorkshopOpeningHours> openingHours,
  ) async {
    try {
      final repository = ref.read(serviceRepositoryProvider);
      await repository.updateBulkWorkshopOpeningHours(
        adminId: adminId,
        openingHours: openingHours,
      );

      // Refresh the data after update
      await fetchOpeningHours();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Provider for filtered services by category
final filteredServicesByCategoryProvider =
    Provider.family<List<ServiceModel>, String>((ref, category) {
      final adminId = ref.watch(selectedWorkshopProvider);
      if (adminId == null) return [];

      final servicesAsync = ref.watch(workshopServicesProvider(adminId));

      return servicesAsync.when(
        data: (services) {
          if (category.isEmpty || category.toLowerCase() == 'all') {
            return services;
          }
          return services
              .where(
                (service) =>
                    service.category?.toLowerCase() == category.toLowerCase(),
              )
              .toList();
        },
        loading: () => [],
        error: (_, __) => [],
      );
    });

// Provider to hold the currently selected workshop ID
final selectedWorkshopProvider = StateProvider<String?>((ref) => null);

// Provider for service categories
final serviceCategoriesProvider = Provider<List<String>>((ref) {
  final adminId = ref.watch(selectedWorkshopProvider);
  if (adminId == null) return [];

  final servicesAsync = ref.watch(workshopServicesProvider(adminId));

  return servicesAsync.when(
    data: (services) {
      final categories =
          services
              .where((service) => service.category != null)
              .map((service) => service.category!)
              .toSet()
              .toList();
      categories.sort();
      return ['All', ...categories];
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider for selected category filter
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

// Helper provider to check if workshop is open on a specific day
final isWorkshopOpenProvider = Provider.family<bool, (String, String)>((
  ref,
  params,
) {
  final (adminId, dayOfWeek) = params;
  final openingHoursAsync = ref.watch(workshopOpeningHoursProvider(adminId));

  return openingHoursAsync.when(
    data: (openingHours) {
      final dayHours = openingHours.firstWhere(
        (hours) => hours.dayOfWeek.toLowerCase() == dayOfWeek.toLowerCase(),
        orElse:
            () => WorkshopOpeningHours(
              id: '0',
              adminId: adminId,
              dayOfWeek: dayOfWeek,
              isOpen: false,
              createdAt: DateTime.now(),
            ),
      );
      return dayHours.isOpen;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

// Provider to get opening hours for a specific day
final dayOpeningHoursProvider = Provider.family<
  WorkshopOpeningHours?,
  (String, String)
>((ref, params) {
  final (adminId, dayOfWeek) = params;
  final openingHoursAsync = ref.watch(workshopOpeningHoursProvider(adminId));

  return openingHoursAsync.when(
    data: (openingHours) {
      try {
        return openingHours.firstWhere(
          (hours) => hours.dayOfWeek.toLowerCase() == dayOfWeek.toLowerCase(),
        );
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
