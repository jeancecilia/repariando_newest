// lib/src/features/workshop/data/service_repository.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_mobile/src/features/home/domain/service_model.dart';
import 'package:repairando_mobile/src/features/home/domain/workshop_opening_hour_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  final supabase = Supabase.instance.client;
  return ServiceRepository(supabase);
});

class ServiceRepository {
  final SupabaseClient _client;

  ServiceRepository(this._client);

  /// Fetch all services for a specific workshop/admin with service details
  Future<List<ServiceModel>> fetchWorkshopServices(String adminId) async {
    try {
      final response = await _client
          .from('admin_services')
          .select('''
            id,
            admin_id,
            service_id,
            is_available,
            price,
            duration_minutes,
            created_at,
            services (
              service,
              description,
              category
            )
          ''')
          .eq('admin_id', adminId)
          .eq('is_available', true)
          .order('created_at', ascending: false);

      return response.map((json) => ServiceModel.fromJson(json)).toList();
        } catch (e) {
      throw Exception('fetch_services_error: ${e.toString()}');
    }
  }

  /// Fetch workshop opening hours for a specific admin/workshop
  Future<List<WorkshopOpeningHours>> fetchWorkshopOpeningHours(
    String adminId,
  ) async {
    try {
      final response = await _client
          .from('workshop_opening_hours')
          .select('*')
          .eq('admin_id', adminId)
          .order('day_of_week');

      final openingHours =
          response
              .map((json) => WorkshopOpeningHours.fromJson(json))
              .toList();

      // If no data found, return default closed hours
      if (openingHours.isEmpty) {
        return _getDefaultClosedHours(adminId);
      }

      return openingHours;
        } catch (e) {
      // Return default closed hours on error
      return _getDefaultClosedHours(adminId);
    }
  }

  /// Get default closed hours for all days of the week
  List<WorkshopOpeningHours> _getDefaultClosedHours(String adminId) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days
        .map(
          (day) => WorkshopOpeningHours(
            id: '0',
            adminId: adminId,
            dayOfWeek: day,
            isOpen: false,
            createdAt: DateTime.now(),
          ),
        )
        .toList();
  }

  /// Update workshop opening hours
  Future<void> updateWorkshopOpeningHours({
    required String adminId,
    required String dayOfWeek,
    required bool isOpen,
    String? openTime,
    String? closeTime,
    String? breakStart,
    String? breakEnd,
  }) async {
    try {
      // Check if record exists
      final existing =
          await _client
              .from('workshop_opening_hours')
              .select('id')
              .eq('admin_id', adminId)
              .eq('day_of_week', dayOfWeek)
              .maybeSingle();

      final data = {
        'admin_id': adminId,
        'day_of_week': dayOfWeek,
        'is_open': isOpen,
        'open_time': openTime,
        'close_time': closeTime,
        'break_start': breakStart,
        'break_end': breakEnd,
      };

      if (existing != null) {
        // Update existing record
        await _client
            .from('workshop_opening_hours')
            .update(data)
            .eq('id', existing['id']);
      } else {
        // Insert new record
        await _client.from('workshop_opening_hours').insert(data);
      }
    } catch (e) {
      throw Exception('update_opening_hours_error: ${e.toString()}');
    }
  }

  /// Bulk update workshop opening hours
  Future<void> updateBulkWorkshopOpeningHours({
    required String adminId,
    required List<WorkshopOpeningHours> openingHours,
  }) async {
    try {
      // Delete existing records
      await _client
          .from('workshop_opening_hours')
          .delete()
          .eq('admin_id', adminId);

      // Insert new records
      final dataList =
          openingHours
              .map(
                (hours) => {
                  'admin_id': adminId,
                  'day_of_week': hours.dayOfWeek,
                  'is_open': hours.isOpen,
                  'open_time': hours.openTime,
                  'close_time': hours.closeTime,
                  'break_start': hours.breakStart,
                  'break_end': hours.breakEnd,
                },
              )
              .toList();

      await _client.from('workshop_opening_hours').insert(dataList);
    } catch (e) {
      throw Exception('bulk_update_opening_hours_error: ${e.toString()}');
    }
  }

  /// Fetch all available services (from services table)
  Future<List<Map<String, dynamic>>> fetchAllServices() async {
    try {
      final response = await _client
          .from('services')
          .select('*')
          .order('category');

      return response.cast<Map<String, dynamic>>();
        } catch (e) {
      throw Exception('fetch_all_services_error: ${e.toString()}');
    }
  }

  /// Add a service to a workshop
  Future<void> addServiceToWorkshop({
    required String adminId,
    required String serviceId,
    required double price,
    required int durationMinutes,
  }) async {
    try {
      await _client.from('admin_services').insert({
        'admin_id': adminId,
        'service_id': serviceId,
        'price': price,
        'duration_minutes': durationMinutes,
        'is_available': true,
      });
    } catch (e) {
      throw Exception('add_service_error: ${e.toString()}');
    }
  }

  /// Update service availability
  Future<void> updateServiceAvailability({
    required int serviceId,
    required bool isAvailable,
  }) async {
    try {
      await _client
          .from('admin_services')
          .update({'is_available': isAvailable})
          .eq('id', serviceId);
    } catch (e) {
      throw Exception('update_service_error: ${e.toString()}');
    }
  }

  /// Update service price and duration
  Future<void> updateServiceDetails({
    required int serviceId,
    required double price,
    required int durationMinutes,
  }) async {
    try {
      await _client
          .from('admin_services')
          .update({'price': price, 'duration_minutes': durationMinutes})
          .eq('id', serviceId);
    } catch (e) {
      throw Exception('update_service_details_error: ${e.toString()}');
    }
  }
}
