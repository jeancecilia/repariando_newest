import 'package:repairando_web/src/features/home/domain/working_setting_model.dart';
import 'package:repairando_web/src/features/home/domain/workshop_opening_hour_model.dart';
import 'package:repairando_web/src/infra/custom_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkshopSettingRepository {
  final SupabaseClient _client;

  WorkshopSettingRepository(this._client);

  Future<WorkshopSettingModel> fetchWorkshopProfile(String userId) async {
    try {
      final response =
          await _client
              .from('admin')
              .select()
              .eq('userId', userId)
              .maybeSingle();

      if (response == null) {
        throw CustomException("Workshop profile not found.");
      }

      return WorkshopSettingModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException("Unexpected error occurred.");
    }
  }

  Future<WorkshopSettingModel> updateWorkshopProfile(
    WorkshopUpdateModel updateModel,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw CustomException("User is not authenticated.");
      }

      final updates = updateModel.toJson();
      updates['userId'] = userId;

      // Upload profile image if provided
      if (updateModel.profileImage != null) {
        try {
          final imagePath = 'profile_images/${userId}_Profile_Picture.jpg';

          final uploadResponse = await _client.storage
              .from('admin-profile')
              .uploadBinary(
                imagePath,
                updateModel.profileImage!,
                fileOptions: const FileOptions(
                  upsert: true,
                  contentType: 'image/jpeg', // Add content type
                ),
              );

          final imageUrl = _client.storage
              .from('admin-profile')
              .getPublicUrl(imagePath);

          updates['profile_image'] = imageUrl;
        } catch (storageError) {
          throw CustomException(
            "Failed to upload profile image: $storageError",
          );
        }
      }

      // Upload legal document if provided
      if (updateModel.legalDocument != null) {
        try {
          final docPath = 'legal_documents/${userId}_Legal_Documents.pdf';

          final uploadResponse = await _client.storage
              .from('workshop-documents')
              .uploadBinary(
                docPath,
                updateModel.legalDocument!,
                fileOptions: const FileOptions(
                  upsert: true,
                  contentType: 'application/pdf', // Add content type
                ),
              );

          final docUrl = _client.storage
              .from('workshop-documents')
              .getPublicUrl(docPath);

          updates['legal_document'] = docUrl;
        } catch (storageError) {
          throw CustomException(
            "Failed to upload legal document: $storageError",
          );
        }
      }

      // Update the database
      final response =
          await _client
              .from('admin')
              .update(updates)
              .eq('userId', userId)
              .select()
              .single();

      return WorkshopSettingModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw CustomException(e.message);
    } on StorageException catch (e) {
      throw CustomException("Storage error: ${e.message}");
    } catch (e) {
      throw CustomException("Unable to update profile: $e");
    }
  }

  Future<void> saveOpeningHours(
    String adminId,
    List<WorkshopOpeningHour> hours,
  ) async {
    final data = hours.map((e) => e.toJson(adminId)).toList();

    // optional: delete existing rows to replace
    await _client
        .from('workshop_opening_hours')
        .delete()
        .eq('admin_id', adminId);

    final response = await _client.from('workshop_opening_hours').insert(data);

    if (response != null && response.error != null) {
      throw Exception(response.error!.message);
    }
  }

  Future<List<WorkshopOpeningHour>> fetchOpeningHours(String adminId) async {
    final data = await _client
        .from('workshop_opening_hours')
        .select()
        .eq('admin_id', adminId);

    return (data as List).map((item) {
      return WorkshopOpeningHour(
        dayOfWeek: item['day_of_week'],
        isOpen: item['is_open'],
        openTime: item['open_time'],
        closeTime: item['close_time'],
        breakStart: item['break_start'],
        breakEnd: item['break_end'],
      );
    }).toList();
  }
}
