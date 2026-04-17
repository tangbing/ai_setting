import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_session_events.dart';
import '../core/network/api_client.dart';
import '../core/storage/auth_storage.dart';
import '../models/auth_session.dart';
import '../services/auth_service.dart';

enum AuthMode { login, register }

class AuthState {
  const AuthState({
    required this.mode,
    required this.session,
    required this.isInitializing,
    required this.isSubmitting,
    required this.errorMessage,
  });

  final AuthMode mode;
  final AuthSession? session;
  final bool isInitializing;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isAuthenticated => session != null;

  AuthState copyWith({
    AuthMode? mode,
    AuthSession? session,
    bool? isInitializing,
    bool? isSubmitting,
    String? errorMessage,
    bool clearSession = false,
    bool clearError = false,
  }) {
    return AuthState(
      mode: mode ?? this.mode,
      session: clearSession ? null : session ?? this.session,
      isInitializing: isInitializing ?? this.isInitializing,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  factory AuthState.initial() {
    return const AuthState(
      mode: AuthMode.login,
      session: null,
      isInitializing: true,
      isSubmitting: false,
      errorMessage: null,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(
    this._authService,
    this._authStorage,
    this._apiClient,
    this._authSessionEvents,
  ) : super(AuthState.initial()) {
    _sessionEventSub = _authSessionEvents.stream.listen(_handleSessionEvent);
    _restoreSession();
  }

  final AuthService _authService;
  final AuthStorage _authStorage;
  final ApiClient _apiClient;
  final AuthSessionEvents _authSessionEvents;
  late final StreamSubscription<AuthSessionEvent> _sessionEventSub;

  Future<void> _restoreSession() async {
    try {
      final session = await _authStorage.readSession();
      state = state.copyWith(
        session: session,
        isInitializing: false,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isInitializing: false,
        clearSession: true,
      );
    }
  }

  Future<void> _handleSessionEvent(AuthSessionEvent event) async {
    if (event != AuthSessionEvent.unauthorized || !state.isAuthenticated) {
      return;
    }
    await logout();
    state = state.copyWith(errorMessage: '登录已失效，请重新登录');
  }

  void switchMode(AuthMode mode) {
    if (state.mode == mode) {
      return;
    }
    state = state.copyWith(mode: mode, clearError: true);
  }

  Future<bool> submit({
    required String username,
    required String password,
  }) async {
    if (state.isSubmitting) {
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final normalizedUsername = username.trim();
      final session = state.mode == AuthMode.register
          ? await _authService.register(
              username: normalizedUsername,
              password: password,
            )
          : await _authService.login(
              username: normalizedUsername,
              password: password,
            );
      await _authStorage.saveSession(session);

      state = state.copyWith(
        session: session,
        isInitializing: false,
        isSubmitting: false,
        clearError: true,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _apiClient.resolveMessage(
          error,
          fallback: state.mode == AuthMode.register ? '注册失败，请稍后重试' : '登录失败，请稍后重试',
        ),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authStorage.clearSession();
    state = state.copyWith(
      clearSession: true,
      clearError: true,
      isInitializing: false,
      isSubmitting: false,
    );
  }

  @override
  void dispose() {
    _sessionEventSub.cancel();
    super.dispose();
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiClientProvider));
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(authStorageProvider),
    ref.watch(apiClientProvider),
    ref.watch(authSessionEventsProvider),
  );
});
