import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:frontend/models/user.dart';
import '../services/user_service.dart';
import 'auth_provider.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.read(apiClientProvider));
});

class UserSearchNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final UserService _userService;
  UserSearchNotifier(this._userService) : super(const AsyncValue.data([]));

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final results = await _userService.searchUsers(query.trim());
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() => state = const AsyncValue.data([]);
}

final userSearchProvider =
    StateNotifierProvider<UserSearchNotifier, AsyncValue<List<UserModel>>>((
      ref,
    ) {
      return UserSearchNotifier(ref.read(userServiceProvider));
    });

class ProfileEditNotifier extends StateNotifier<AsyncValue<void>> {
  final UserService _userService;
  final Ref _ref;

  ProfileEditNotifier(this._userService, this._ref)
    : super(const AsyncValue.data(null));

  Future<bool> updateProfile({String? name, String? avatar}) async {
    state = const AsyncValue.loading();
    try {
      final updatedUser = await _userService.updateProfile(
        name: name,
        avatar: avatar,
      );
      _ref.read(authProvider.notifier).updateLocalUser(updatedUser);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final profileEditProvider =
    StateNotifierProvider<ProfileEditNotifier, AsyncValue<void>>((ref) {
      return ProfileEditNotifier(ref.read(userServiceProvider), ref);
    });
