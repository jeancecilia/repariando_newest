import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:repairando_mobile/src/features/home/data/location_respository.dart';
import 'package:repairando_mobile/src/features/home/presentation/controllers/workshop_controller.dart';

// Provider for current user location
final userLocationProvider =
    StateNotifierProvider<UserLocationNotifier, AsyncValue<Position?>>((ref) {
      return UserLocationNotifier();
    });

class UserLocationNotifier extends StateNotifier<AsyncValue<Position?>> {
  UserLocationNotifier() : super(const AsyncValue.data(null));

  Future<void> getCurrentLocation() async {
    state = const AsyncValue.loading();
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        state = AsyncValue.data(position);
      } else {
        state = const AsyncValue.error(
          'Unable to get current location. Please check your location settings.',
          StackTrace.empty,
        );
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        'Location error: ${error.toString()}',
        stackTrace,
      );
    }
  }

  void clearLocation() {
    state = const AsyncValue.data(null);
  }

  // Method to refresh location
  Future<void> refreshLocation() async {
    await getCurrentLocation();
  }
}

// Provider for radius slider value with validation
final radiusProvider = StateNotifierProvider<RadiusNotifier, double>((ref) {
  return RadiusNotifier();
});

class RadiusNotifier extends StateNotifier<double> {
  RadiusNotifier() : super(10.0); // Default 10km

  void updateRadius(double newRadius) {
    // Ensure radius is within valid bounds
    if (newRadius >= 1.0 && newRadius <= 400.0) {
      state = newRadius;
    }
  }

  void resetToDefault() {
    state = 10.0;
  }
}

// Provider for location permission status
final locationPermissionProvider = FutureProvider<bool>((ref) async {
  return await LocationService.checkLocationPermission();
});

// Provider for workshops filtered by location and radius
final locationFilteredWorkshopsProvider =
    FutureProvider.autoDispose<List<WorkshopWithDistance>>((ref) async {
      final userLocationAsync = ref.watch(userLocationProvider);
      final radius = ref.watch(radiusProvider);
      final workshopsAsync = ref.watch(workshopsProvider);

      return userLocationAsync.when(
        data: (userLocation) async {
          if (userLocation == null) return [];

          return workshopsAsync.when(
            data: (workshops) async {
              if (workshops.isEmpty) return [];

              try {
                final filteredWorkshops =
                    await LocationService.filterWorkshopsByRadius(
                      workshops: workshops,
                      userLocation: userLocation,
                      radiusKm: radius,
                    );

                return filteredWorkshops;
              } catch (e) {
                return [];
              }
            },
            loading: () => [],
            error: (error, stackTrace) {
              return [];
            },
          );
        },
        loading: () => [],
        error: (error, stackTrace) {
          return [];
        },
      );
    });

// Provider to check if location filtering is enabled
final isLocationFilterEnabledProvider = Provider<bool>((ref) {
  final userLocation = ref.watch(userLocationProvider);
  return userLocation.value != null;
});

// Provider for location status message
final locationStatusProvider = Provider<String>((ref) {
  final userLocationAsync = ref.watch(userLocationProvider);
  final isEnabled = ref.watch(isLocationFilterEnabledProvider);

  return userLocationAsync.when(
    data: (location) {
      if (location == null) {
        return 'Enable location for nearby workshops';
      } else {
        return 'Location-based search enabled';
      }
    },
    loading: () => 'Getting your location...',
    error: (error, _) => 'Location unavailable - $error',
  );
});

// Provider for workshop count with location filtering
final workshopCountProvider = Provider<int>((ref) {
  final locationFilteredAsync = ref.watch(locationFilteredWorkshopsProvider);
  final isLocationEnabled = ref.watch(isLocationFilterEnabledProvider);
  final showSuggestions = ref.watch(showSuggestionsProvider);
  final filteredWorkshops = ref.watch(filteredWorkshopsProvider);

  if (showSuggestions) {
    return filteredWorkshops.length;
  } else if (isLocationEnabled) {
    return locationFilteredAsync.value?.length ?? 0;
  } else {
    final workshopsAsync = ref.watch(workshopsProvider);
    return workshopsAsync.value?.length ?? 0;
  }
});
