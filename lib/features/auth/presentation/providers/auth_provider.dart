import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/database/secure_storage_provider.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(db, storage);
});

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;
  final bool isLoading;

  AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(AuthState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    try {
      final user = await _repo.getCurrentUser();
      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repo.login(email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> register(String fullName, String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repo.register(fullName, email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repo.logout();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  void setAuthenticated(UserEntity user) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> updatePreferences({
    String? currencyCode,
    String? themePreference,
    bool? biometricEnabled,
    String? fullName,
    String? email,
  }) async {
    if (state.user == null) return;
    await _repo.updatePreferences(
      currencyCode: currencyCode,
      themePreference: themePreference,
      biometricEnabled: biometricEnabled,
      fullName: fullName,
      email: email,
    );
    final updatedUser = state.user!.copyWith(
      currencyCode: currencyCode,
      themePreference: themePreference,
      biometricEnabled: biometricEnabled,
      fullName: fullName,
      email: email,
    );
    state = state.copyWith(user: updatedUser);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
