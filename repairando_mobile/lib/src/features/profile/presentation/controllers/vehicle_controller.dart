import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/features/auth/data/auth_repository.dart';
import 'package:repairando_mobile/src/features/profile/data/vehicle_repository.dart';
import 'package:repairando_mobile/src/features/profile/domain/vehicle_model.dart';

final vehicleControllerProvider =
    StateNotifierProvider<VehicleController, AsyncValue<void>>((ref) {
      final authRepo = ref.read(authRepositoryProvider);
      final vehicleRepo = ref.read(vehicleRepositoryProvider);
      return VehicleController(authRepo, vehicleRepo, ref);
    });

// Provider to fetch user's vehicles
final userVehiclesProvider = FutureProvider<List<Vehicle>>((ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  final vehicleRepo = ref.read(vehicleRepositoryProvider);

  final userId = authRepo.currentUser?.id;
  if (userId == null) {
    throw Exception('user_not_logged_in'.tr());
  }

  return vehicleRepo.fetchUserVehicles(userId);
});

// Provider for refreshing vehicles list
final vehiclesRefreshProvider = StateProvider<int>((ref) => 0);

// Auto-refresh provider that depends on refresh state
final refreshableVehiclesProvider = FutureProvider<List<Vehicle>>((ref) async {
  // Watch refresh state to trigger rebuilds
  ref.watch(vehiclesRefreshProvider);

  final authRepo = ref.read(authRepositoryProvider);
  final vehicleRepo = ref.read(vehicleRepositoryProvider);

  final userId = authRepo.currentUser?.id;
  if (userId == null) {
    throw Exception('user_not_logged_in'.tr());
  }

  return vehicleRepo.fetchUserVehicles(userId);
});

class VehicleController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  final VehicleRepository _vehicleRepository;
  final Ref _ref;

  File? _vehicleImageFile;
  File? get vehicleImageFile => _vehicleImageFile;

  VehicleController(this._authRepository, this._vehicleRepository, this._ref)
    : super(const AsyncData(null));

  Future<File?> pickVehicleImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        _vehicleImageFile = File(picked.path);
        state = const AsyncData(null);
        return _vehicleImageFile;
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
    return null;
  }

  Future<void> addVehicle({
    required String vehicleName,
    required String? vin,
    required String? vehicleMake,
    required String? vehicleModel,
    required String? vehicleYear,
    required String? engineType,
    required String? mileage,
  }) async {
    final userId = _authRepository.currentUser?.id;
    if (userId == null) {
      state = AsyncError(
        Exception('user_not_logged_in'.tr()),
        StackTrace.current,
      );
      return;
    }

    final vehicle = Vehicle(
      createdAt: DateTime.now(),
      userId: userId,
      vehicleImage: null,
      vehicleName: vehicleName,
      vin: vin,
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      vehicleYear: vehicleYear,
      engineType: engineType,
      mileage: mileage,
    );

    try {
      state = const AsyncLoading();
      await _vehicleRepository.addVehicle(
        vehicle: vehicle,
        vehicleImage: _vehicleImageFile,
      );
      _vehicleImageFile = null;
      state = const AsyncData(null);

      // Refresh the vehicles list
      _refreshVehiclesList();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    try {
      state = const AsyncLoading();
      await _vehicleRepository.deleteVehicle(vehicleId);
      state = const AsyncData(null);

      // Refresh the vehicles list
      _refreshVehiclesList();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateVehicle({
    required String vehicleId,
    required String vehicleName,
    required String? vin,
    required String? vehicleMake,
    required String? vehicleModel,
    required String? vehicleYear,
    required String? engineType,
    required String? mileage,
    File? newVehicleImage,
  }) async {
    final userId = _authRepository.currentUser?.id;
    if (userId == null) {
      state = AsyncError(
        Exception('user_not_logged_in'.tr()),
        StackTrace.current,
      );
      return;
    }

    final vehicle = Vehicle(
      createdAt: DateTime.now(), // This will be ignored in update
      userId: userId,
      vehicleImage: null, // Will be handled separately
      vehicleName: vehicleName,
      vin: vin,
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      vehicleYear: vehicleYear,
      engineType: engineType,
      mileage: mileage,
    );

    try {
      state = const AsyncLoading();
      await _vehicleRepository.updateVehicle(
        vehicleId: vehicleId,
        vehicle: vehicle,
        vehicleImage: newVehicleImage ?? _vehicleImageFile,
      );
      _vehicleImageFile = null;
      state = const AsyncData(null);

      // Refresh the vehicles list
      _refreshVehiclesList();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void _refreshVehiclesList() {
    // Increment refresh counter to trigger provider refresh
    final currentValue = _ref.read(vehiclesRefreshProvider);
    _ref.read(vehiclesRefreshProvider.notifier).state = currentValue + 1;
  }

  Future<void> refreshVehicles() async {
    _refreshVehiclesList();
  }
}
