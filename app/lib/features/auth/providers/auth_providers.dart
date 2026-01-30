import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../data/auth_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseClientProvider.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

class AuthStateData {
  const AuthStateData({
    required this.isLoading,
    this.errorMessage,
  });

  final bool isLoading;
  final String? errorMessage;

  AuthStateData copyWith({bool? isLoading, String? errorMessage}) {
    return AuthStateData(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthStateData> {
  AuthController(this._authRepository)
      : super(const AuthStateData(isLoading: false));

  final AuthRepository _authRepository;

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authRepository.signIn(email: email, password: password);
      state = state.copyWith(isLoading: false, errorMessage: null);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authRepository.signUp(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
      );
      state = state.copyWith(isLoading: false, errorMessage: null);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authRepository.signOut();
      state = state.copyWith(isLoading: false, errorMessage: null);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthStateData>(
  (ref) => AuthController(ref.watch(authRepositoryProvider)),
);

class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier(this._client) {
    session = _client.auth.currentSession;
    _sub = _client.auth.onAuthStateChange.listen((event) {
      session = event.session;
      notifyListeners();
    });
  }

  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _sub;
  Session? session;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final authRefreshNotifierProvider = Provider<AuthRefreshNotifier>((ref) {
  final notifier = AuthRefreshNotifier(ref.watch(supabaseClientProvider));
  ref.onDispose(notifier.dispose);
  return notifier;
});
