import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/constants/secure_storage.dart';
import 'package:repairando_mobile/src/features/auth/domain/customer_model.dart';
import 'package:repairando_mobile/src/infra/custom_exception.dart';

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
    required String name,
    required String surname,
    required String email,
    required String password,
  }) async {
    try {
      final existingUser =
          await _client
              .from('customers')
              .select()
              .eq('email', email)
              .maybeSingle();
      if (existingUser != null) {
        throw CustomException('email_already_registered'.tr());
      }

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {},
      );

      if (response.user == null) {
        throw CustomException('signup_failed_verify_email'.tr());
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
    required CustomerModel user,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        type: OtpType.email,
        token: otp,
        email: user.email,
      );

      if (response.user == null || response.session == null) {
        throw CustomException('otp_verification_failed'.tr());
      }

      if (response.user != null) {
        final storeUser = CustomerModel(
          id: response.user!.id,
          name: user.name,
          surname: user.surname,
          email: user.email,
          profileImage: '',
        );

        // Store user data in your users table
        await _storeUserData(storeUser);
        await _storeTokens(response.session!);
      }
    } on AuthException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException('unexpected_otp_error'.tr());
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
        throw CustomException('login_failed'.tr());
      }

      // Step 2: Check if user exists in customers table
      final customerProfile =
          await _client
              .from('customers')
              .select('id')
              .eq('id', user.id)
              .maybeSingle();

      if (customerProfile == null) {
        // User exists in auth but not in customers table
        // This means they're either an admin or not properly registered
        await _client.auth.signOut();

        throw CustomException('only_customers_allowed'.tr());
      }

      await _storeTokens(session);

      // Optional: You can also store customer info in local storage for quick access
      // await _storeCustomerInfo(customerProfile);
    } on AuthException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException('invalid_email_password'.tr());
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      await secureStorage.deleteAll();
    } catch (e) {
      throw CustomException('signout_error'.tr());
    }
  }

  // Helper method to store user data
  Future<void> _storeUserData(CustomerModel user) async {
    final insertResponse =
        await _client
            .from('customers')
            .upsert(user.toMap()) // Use upsert to handle existing users
            .select();

    if (insertResponse.isEmpty) {
      throw CustomException('store_user_failed'.tr());
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
