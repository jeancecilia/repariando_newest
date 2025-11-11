import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_web/src/constants/secure_storage.dart';
import 'package:repairando_web/src/features/auth/domain/workshop_registration_model.dart';
import 'package:repairando_web/src/infra/custom_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = Supabase.instance.client;
  return AuthRepository(client);
});

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);
  SupabaseClient get client => _client;
  User? get currentUser => _client.auth.currentUser;

  Future<void> registration({
    required String email,
    required String password,
  }) async {
    try {
      final existingUser =
          await _client.from('admin').select().eq('email', email).maybeSingle();
      if (existingUser != null) {
        throw CustomException('auth_email_already_registered'.tr());
      }

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {},
      );

      if (response.user == null) {
        throw CustomException('auth_signup_failed'.tr());
      }
    } on PostgrestException catch (e) {
      throw CustomException(e.message);
    } on AuthException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifyOtpAndStoreUser({
    required String otp,
    required WorkshopRegistrationModel user,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        type: OtpType.email,
        token: otp,
        email: user.email,
      );

      if (response.user == null || response.session == null) {
        throw CustomException('auth_otp_verification_failed'.tr());
      }

      if (response.user != null) {
        final storeUser = WorkshopRegistrationModel(
          userId: response.user!.id,
          email: user.email,
        );

        // Store user data in your users table
        await _storeUserData(storeUser);
      }
    } on AuthException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException('auth_otp_verification_error'.tr());
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      // Step 1: Authenticate with Supabase Auth
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      final session = response.session;

      if (user == null || session == null) {
        throw CustomException('auth_login_failed'.tr());
      }

      // Step 2: Check if user exists in customers table
      final customerProfile =
          await _client
              .from('customers')
              .select('id')
              .eq('id', user.id)
              .maybeSingle();

      if (customerProfile != null) {
        // User exists in auth but not in customers table
        // This means they're either an admin or not properly registered
        await _client.auth.signOut();

        throw CustomException('auth_customers_only'.tr());
      }
    } on AuthException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException('auth_invalid_credentials'.tr());
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw CustomException('auth_signout_error'.tr());
    }
  }

  // Helper method to store user data
  Future<void> _storeUserData(WorkshopRegistrationModel user) async {
    try {
      final insertResponse =
          await _client
              .from('admin')
              .upsert(user.toJson()) // Use upsert to handle existing users
              .select();

      if (insertResponse.isEmpty) {
        throw CustomException('auth_store_user_data_failed'.tr());
      }
    } catch (e) {
      throw CustomException('auth_store_user_data_failed'.tr());
    }
  }

  Future<void> completeWorkshopProfile(WorkshopRegistrationModel user) async {
    try {
      final updates = user.toJson();

      // ✅ Ensure userId is included for the update
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw CustomException('auth_user_not_authenticated'.tr());
      }
      updates['userId'] = userId;

      // Upload profile image
      if (user.profileImage != null) {
        try {
          final imagePath = 'profile_images/${userId}_Profile_Picture';
          await _client.storage
              .from('admin-profile')
              .uploadBinary(
                imagePath,
                user.profileImage!,
                fileOptions: const FileOptions(upsert: true),
              );

          final imageUrl = _client.storage
              .from('admin-profile')
              .getPublicUrl(imagePath);
          updates['profile_image'] = imageUrl;
        } catch (e) {
          throw CustomException('workshop_profile_image_upload_failed'.tr());
        }
      }

      // Upload legal document
      if (user.legalDocument != null) {
        try {
          final docPath = 'legal_documents/${userId}_Legal_Documents';
          await _client.storage
              .from('workshop-documents')
              .uploadBinary(
                docPath,
                user.legalDocument!,
                fileOptions: const FileOptions(upsert: true),
              );

          final docUrl = _client.storage
              .from('workshop-documents')
              .getPublicUrl(docPath);
          updates['legal_document'] = docUrl;
        } catch (e) {
          throw CustomException('workshop_legal_document_upload_failed'.tr());
        }
      }

      try {
        final response =
            await _client
                .from('admin')
                .update(updates)
                .eq('userId', userId)
                .select();

        if (response.isEmpty) {
          throw CustomException('auth_profile_update_failed'.tr());
        }
      } catch (e) {
        if (e.toString().contains('storage')) {
          throw CustomException('workshop_storage_error'.tr());
        }
        throw CustomException('workshop_profile_update_error'.tr());
      }
    } catch (e) {
      if (e is CustomException) {
        rethrow;
      }
      throw CustomException('auth_profile_completion_error'.tr());
    }
  }

  // Helper method to store authentication tokens
  Future<void> _storeTokens(Session session) async {
    await secureStorage.write(key: 'access_token', value: session.accessToken);
    await secureStorage.write(
      key: 'refresh_token',
      value: session.refreshToken,
    );
    await secureStorage.write(key: 'user_id', value: session.user.id);
  }

  // Method to check if user is authenticated
  bool get isAuthenticated => _client.auth.currentUser != null;
}
