import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/features/profile/domain/vehicle_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:repairando_mobile/src/infra/custom_exception.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final client = Supabase.instance.client;
  return VehicleRepository(client);
});

class VehicleRepository {
  final SupabaseClient _client;

  VehicleRepository(this._client);

  Future<void> addVehicle({
    required Vehicle vehicle,
    File? vehicleImage, // optional image
  }) async {
    try {
      String? imageUrl;

      if (vehicleImage != null) {
        final ext = vehicleImage.path.split('.').last;
        final fileName =
            'vehicle_${vehicle.userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

        await _client.storage
            .from('vehicle-images')
            .upload(fileName, vehicleImage);

        imageUrl = _client.storage
            .from('vehicle-images')
            .getPublicUrl(fileName);
      }

      final insertData = vehicle.toMap();
      if (imageUrl != null) {
        insertData['vehicle_image'] = imageUrl;
      }

      await _client.from('vehicles').insert(insertData);
    } catch (e, st) {
      throw CustomException('error_adding_vehicle'.tr(), stackTrace: st);
    }
  }

  Future<List<Vehicle>> fetchUserVehicles(String userId) async {
    try {
      final response = await _client
          .from('vehicles')
          .select()
          .eq('userId', userId)
          .eq('archive', 0)
          .order('created_at', ascending: false);

      return (response as List)
          .map((vehicleData) => Vehicle.fromMap(vehicleData))
          .toList();
    } catch (e, st) {
      throw CustomException('error_fetching_vehicles'.tr(), stackTrace: st);
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _client.from('vehicles').update({'archive': 1}).eq('id', vehicleId);
    } catch (e, st) {
      throw CustomException('error_archiving_vehicle'.tr(), stackTrace: st);
    }
  }

  Future<void> updateVehicle({
    required String vehicleId,
    required Vehicle vehicle,
    File? vehicleImage,
  }) async {
    try {
      String? imageUrl;

      if (vehicleImage != null) {
        final ext = vehicleImage.path.split('.').last;
        final fileName =
            'vehicle_${vehicle.userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

        await _client.storage
            .from('vehicle-images')
            .upload(fileName, vehicleImage);

        imageUrl = _client.storage
            .from('vehicle-images')
            .getPublicUrl(fileName);
      }

      final updateData = vehicle.toMap();
      if (imageUrl != null) {
        updateData['vehicle_image'] = imageUrl;
      }

      await _client.from('vehicles').update(updateData).eq('id', vehicleId);
    } catch (e, st) {
      throw CustomException('error_updating_vehicle'.tr(), stackTrace: st);
    }
  }
}
