import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers.dart';
import 'auth_service.dart';
import 'google_user.dart';

enum AuthStatus { unknown, signedOut, signingIn, signedIn }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
  });

  final AuthStatus status;
  final GoogleUser? user;
  final String? error;

  AuthState copyWith({AuthStatus? status, GoogleUser? user, String? error}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
      );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._service) : super(const AuthState());

  final AuthService _service;

  bool get isConfigured => _service.isConfigured;

  /// Called at startup to restore an existing session.
  Future<void> bootstrap() async {
    final user = await _service.restoreSession();
    state = user != null
        ? AuthState(status: AuthStatus.signedIn, user: user)
        : const AuthState(status: AuthStatus.signedOut);
  }

  Future<void> signIn() async {
    state = state.copyWith(status: AuthStatus.signingIn, error: null);
    try {
      final user = await _service.signIn();
      state = AuthState(status: AuthStatus.signedIn, user: user);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.signedOut,
        error: e is AuthException ? e.message : e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = const AuthState(status: AuthStatus.signedOut);
  }
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.read(appConfigProvider)),
);

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.read(authServiceProvider)),
);

/// Whether OAuth credentials are present (used to show a setup hint).
final authConfiguredProvider = Provider<bool>(
  (ref) => ref.read(appConfigProvider).hasGoogleOAuth,
);
