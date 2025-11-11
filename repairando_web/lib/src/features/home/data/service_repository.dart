// lib/src/features/services/data/service_repository.dart

import 'package:repairando_web/src/features/home/domain/service_model.dart';
import 'package:repairando_web/src/infra/custom_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceRepository {
  final SupabaseClient _client;

  ServiceRepository(this._client);

  Future<List<ServiceModel>> fetchAllServices() async {
    try {
      final response = await _client
          .from('services')
          .select()
          .order('category')
          .order('service');

      return (response as List)
          .map((json) => ServiceModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException(
        "Unexpected error occurred while fetching services.",
      );
    }
  }

  Future<List<AdminServiceModel>> fetchAdminServices(String adminId) async {
    try {
      final response = await _client
          .from('admin_services')
          .select()
          .eq('admin_id', adminId);

      return (response as List)
          .map((json) => AdminServiceModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException(
        "Unexpected error occurred while fetching admin services.",
      );
    }
  }

  Future<List<ServiceWithAvailability>> fetchServicesWithAvailability() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw CustomException("User is not authenticated.");
      }

      // Fetch all services
      final services = await fetchAllServices();

      // Fetch admin services for current user
      final adminServices = await fetchAdminServices(userId);

      // Create a map for quick lookup
      final adminServiceMap = <String, AdminServiceModel>{};
      for (final adminService in adminServices) {
        adminServiceMap[adminService.serviceId] = adminService;
      }

      // Combine the data
      return services.map((service) {
        final adminService = adminServiceMap[service.id];
        return ServiceWithAvailability(
          service: service,
          adminService: adminService,
        );
      }).toList();
    } catch (e) {
      throw CustomException(
        "Unexpected error occurred while fetching services.",
      );
    }
  }

  Future<AdminServiceModel> updateServiceAvailability(
    UpdateServiceRequest request,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw CustomException("User is not authenticated.");
      }

      final updates = request.toJson();
      updates['admin_id'] = userId;

      // Check if admin service already exists
      final existingService =
          await _client
              .from('admin_services')
              .select()
              .eq('admin_id', userId)
              .eq('service_id', request.serviceId)
              .maybeSingle();

      late final Map<String, dynamic> response;

      if (existingService != null) {
        // Update existing record
        response =
            await _client
                .from('admin_services')
                .update(updates)
                .eq('admin_id', userId)
                .eq('service_id', request.serviceId)
                .select()
                .single();
      } else {
        // Insert new record
        response =
            await _client
                .from('admin_services')
                .insert(updates)
                .select()
                .single();
      }

      return AdminServiceModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException("Unable to update service: $e");
    }
  }

  Future<void> deleteServiceAvailability(String serviceId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw CustomException("User is not authenticated.");
      }

      await _client
          .from('admin_services')
          .delete()
          .eq('admin_id', userId)
          .eq('service_id', serviceId);
    } on PostgrestException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException("Unable to delete service availability.");
    }
  }
}
