import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// ─── Core singletons ──────────────────────────────────────────────
final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(storageServiceProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(apiClientProvider));
});

/// ─── Auth state ───────────────────────────────────────────────────
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({required this.status, this.user, this.errorMessage});

  const AuthState.unknown() : this(status: AuthStatus.unknown);
  const AuthState.authenticated(UserModel user)
    : this(status: AuthStatus.authenticated, user: user);
  const AuthState.unauthenticated({String? error})
    : this(status: AuthStatus.unauthenticated, errorMessage: error);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final StorageService _storageService;

  AuthNotifier(this._authService, this._storageService)
    : super(const AuthState.unknown()) {
    _tryAutoLogin();
  }

  /// Called once on app start. If a token exists, validate it against
  /// the backend via GET /me. If valid, restore session; if not, log out.
  Future<void> _tryAutoLogin() async {
    final token = await _storageService.getToken();
    if (token == null) {
      state = const AuthState.unauthenticated();
      return;
    }

    try {
      final user = await _authService.getCurrentUser();
      state = AuthState.authenticated(user);
    } catch (_) {
      // Token invalid/expired — clear it and force login
      await _storageService.deleteToken();
      state = const AuthState.unauthenticated();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      await _storageService.saveToken(result['token']);
      state = AuthState.authenticated(result['user']);
      return true;
    } on ApiException catch (e) {
      state = AuthState.unauthenticated(error: e.message);
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      final result = await _authService.login(email: email, password: password);
      await _storageService.saveToken(result['token']);
      state = AuthState.authenticated(result['user']);
      return true;
    } on ApiException catch (e) {
      state = AuthState.unauthenticated(error: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {
      // Ignore server-side failure; proceed with local logout regardless
    }
    await _storageService.deleteToken();
    state = const AuthState.unauthenticated();
  }

  /// Called by ApiClient.onUnauthorized when a 401 is received on any request.
  void forceLogout() {
    state = const AuthState.unauthenticated(
      error: 'Session expired, please log in again',
    );
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = AuthState(status: state.status, user: state.user);
    }
  }

  void updateLocalUser(UserModel updatedUser) {
    if (state.status == AuthStatus.authenticated) {
      state = AuthState.authenticated(updatedUser);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(storageServiceProvider),
  );

  // Wire the API client's 401 callback to force-logout the auth state.
  ref.read(apiClientProvider).onUnauthorized = notifier.forceLogout;

  return notifier;
});
