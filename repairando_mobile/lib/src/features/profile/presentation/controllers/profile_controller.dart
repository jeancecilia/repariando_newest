import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/features/profile/data/profile_repository.dart';
import 'package:repairando_mobile/src/features/auth/data/auth_repository.dart';
import 'package:repairando_mobile/src/features/auth/domain/customer_model.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<CustomerModel?>>((ref) {
      final authRepo = ref.read(authRepositoryProvider);
      final profileRepo = ref.read(profileRepositoryProvider);
      return ProfileController(authRepo, profileRepo);
    });

class ProfileController extends StateNotifier<AsyncValue<CustomerModel?>> {
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;

  File? _profileImageFile;
  File? get profileImageFile => _profileImageFile;

  ProfileController(this._authRepository, this._profileRepository)
    : super(const AsyncLoading()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    state = const AsyncLoading();
    try {
      final userId = _authRepository.currentUser?.id;
      if (userId == null) throw Exception('user_not_logged_in'.tr());

      final profile = await _profileRepository.fetchProfile(userId);
      state = AsyncData(profile);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<File?> pickProfileImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        _profileImageFile = File(pickedFile.path);
        state = AsyncData(state.value); // safely re-emit current value
        return _profileImageFile;
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
    return null;
  }

  Future<void> updateProfile({
    required String name,
    required String surname,
  }) async {
    final userId = _authRepository.currentUser?.id;
    if (userId == null) throw Exception('user_not_logged_in'.tr());

    try {
      state = const AsyncLoading();
      await _profileRepository.updateProfileWithImage(
        userId: userId,
        name: name,
        surname: surname,
        profileImage: _profileImageFile,
      );

      _profileImageFile = null; // reset
      final updated = await _profileRepository.fetchProfile(userId);
      state = AsyncData(updated);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteAccount() async {
    final user = _authRepository.currentUser;
    if (user == null) {
      state = AsyncError(
        Exception('user_not_logged_in'.tr()),
        StackTrace.current,
      );
      return;
    }

    try {
      state = const AsyncLoading();

      // 1. Delete user data from `customers` table
      await _profileRepository.deleteUserData(user.id);

      // 2. Delete user from Supabase Auth
      await _profileRepository.deleteUserFromAuth(user.id);

      // 3. Clear state
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteProfileImage() async {
    final userId = _authRepository.currentUser?.id;
    if (userId == null) {
      state = AsyncError(
        Exception('user_not_logged_in'.tr()),
        StackTrace.current,
      );
      return;
    }

    try {
      state = const AsyncLoading();
      await _profileRepository.deleteProfileImage(userId);

      final updatedProfile = await _profileRepository.fetchProfile(userId);
      state = AsyncData(updatedProfile);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
