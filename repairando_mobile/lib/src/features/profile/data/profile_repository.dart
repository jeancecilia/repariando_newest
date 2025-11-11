import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/features/auth/domain/customer_model.dart';
import 'package:repairando_mobile/src/infra/custom_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = Supabase.instance.client;
  return ProfileRepository(client);
});

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<CustomerModel> fetchProfile(String userId) async {
    try {
      final response =
          await _client
              .from('customers')
              .select()
              .eq('id', userId)
              .maybeSingle();

      if (response == null) {
        throw CustomException('user_profile_not_found'.tr(), code: "NOT_FOUND");
      }

      return CustomerModel.fromMap(response);
    } catch (e, st) {
      throw CustomException('failed_to_fetch_profile'.tr(), stackTrace: st);
    }
  }

  Future<void> updateProfileWithImage({
    required String userId,
    required String name,
    required String surname,
    File? profileImage, // nullable
  }) async {
    try {
      String? imageUrl;

      if (profileImage != null) {
        final fileExt = profileImage.path.split('.').last;
        final fileName =
            'profile_$userId.${DateTime.now().millisecondsSinceEpoch}.$fileExt';

        await _client.storage
            .from('customer-profiles')
            .upload(fileName, profileImage);

        imageUrl = _client.storage
            .from('customer-profiles')
            .getPublicUrl(fileName);
      }

      final updateData = {
        'name': name,
        'surname': surname,
        if (imageUrl != null) 'profile_image': imageUrl,
      };

      final updateResponse =
          await _client
              .from('customers')
              .update(updateData)
              .eq('id', userId)
              .select();

      if (updateResponse.isEmpty) {
        throw CustomException('no_rows_updated'.tr());
      }
    } catch (e, st) {
      throw CustomException('failed_to_update_profile'.tr(), stackTrace: st);
    }
  }

  // Delete from `customers` table
  Future<void> deleteUserData(String userId) async {
    final response = await _client.from('customers').delete().eq('id', userId);
    if (response.error != null) {
      throw Exception(
        '${'error_prefix'.tr()}${'failed_to_delete_user_data'.tr()}: ${response.error!.message}',
      );
    }
  }

  // Delete from Supabase Auth (using admin API)
  Future<void> deleteUserFromAuth(String userId) async {
    try {
      await _client.auth.admin.deleteUser(userId);
    } catch (e) {
      throw Exception(
        '${'error_prefix'.tr()}${'failed_to_delete_user_auth'.tr()}: $e',
      );
    }
  }

  Future<void> deleteProfileImage(String userId) async {
    try {
      // Remove the image field from user record
      await _client
          .from('customers')
          .update({'profile_image': ''})
          .eq('id', userId);
    } catch (e, st) {
      throw CustomException(
        'failed_to_delete_profile_image'.tr(),
        stackTrace: st,
      );
    }
  }
}
