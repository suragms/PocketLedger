import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> register(String fullName, String email, String password);
  Future<void> logout();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> verifyEmail();
  Future<void> updatePreferences({
    String? currencyCode,
    String? themePreference,
    bool? biometricEnabled,
    String? fullName,
    String? email,
  });
}
