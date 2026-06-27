import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:drift/drift.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AppDatabase _db;
  final SecureStorageService _storage;

  AuthRepositoryImpl(this._db, this._storage);

  @override
  Future<UserEntity?> getCurrentUser() async {
    final email = await _storage.getUserEmail();
    final token = await _storage.getToken();
    if (email == null || token == null) return null;

    final query = _db.select(_db.users)..where((t) => t.email.equals(email));
    final user = await query.getSingleOrNull();
    if (user == null) return null;

    return UserEntity(
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      currencyCode: user.currencyCode,
      themePreference: user.themePreference,
      biometricEnabled: user.biometricEnabled,
      emailVerified: user.emailVerified,
    );
  }

  @override
  Future<UserEntity> login(String email, String password) async {
    final query = _db.select(_db.users)..where((t) => t.email.equals(email.trim().toLowerCase()));
    final user = await query.getSingleOrNull();

    if (user == null || user.passwordHash != password) {
      throw Exception('Incorrect email or password');
    }

    await _storage.saveToken('mock_jwt_token_${user.id}');
    await _storage.saveUserEmail(user.email);
    await _storage.saveUserName(user.fullName);
    await _storage.saveCurrency(user.currencyCode);
    await _storage.saveTheme(user.themePreference);
    await _storage.setBiometricEnabled(user.biometricEnabled);

    return UserEntity(
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      currencyCode: user.currencyCode,
      themePreference: user.themePreference,
      biometricEnabled: user.biometricEnabled,
      emailVerified: user.emailVerified,
    );
  }

  @override
  Future<UserEntity> register(String fullName, String email, String password) async {
    // Check if user already exists
    final query = _db.select(_db.users)..where((t) => t.email.equals(email.trim().toLowerCase()));
    final existingUser = await query.getSingleOrNull();
    if (existingUser != null) {
      throw Exception('An account with this email already exists');
    }

    final userId = const Uuid().v4();
    final now = DateTime.now();

    final companion = UsersCompanion.insert(
      id: userId,
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      passwordHash: password,
      currencyCode: const Value('INR'),
      themePreference: const Value('system'),
      biometricEnabled: const Value(false),
      emailVerified: const Value(false),
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.users).insert(companion);

    await _storage.saveToken('mock_jwt_token_$userId');
    await _storage.saveUserEmail(email.trim().toLowerCase());
    await _storage.saveUserName(fullName.trim());
    await _storage.saveCurrency('INR');
    await _storage.saveTheme('system');
    await _storage.setBiometricEnabled(false);

    return UserEntity(
      id: userId,
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      currencyCode: 'INR',
      themePreference: 'system',
      biometricEnabled: false,
      emailVerified: false,
    );
  }

  @override
  Future<void> logout() async {
    await _storage.clearSession(deleteCache: false);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final query = _db.select(_db.users)..where((t) => t.email.equals(email.trim().toLowerCase()));
    final user = await query.getSingleOrNull();
    if (user == null) {
      throw Exception('No account found with this email address');
    }
    // Simulation placeholder
  }

  @override
  Future<void> verifyEmail() async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) throw Exception('No user logged in');

    await (_db.update(_db.users)..where((t) => t.id.equals(currentUser.id)))
        .write(const UsersCompanion(emailVerified: Value(true)));
  }

  @override
  Future<void> updatePreferences({
    String? currencyCode,
    String? themePreference,
    bool? biometricEnabled,
    String? fullName,
    String? email,
  }) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) throw Exception('No user logged in');

    final companion = UsersCompanion(
      currencyCode: currencyCode != null ? Value(currencyCode) : const Value.absent(),
      themePreference: themePreference != null ? Value(themePreference) : const Value.absent(),
      biometricEnabled: biometricEnabled != null ? Value(biometricEnabled) : const Value.absent(),
      fullName: fullName != null ? Value(fullName) : const Value.absent(),
      email: email != null ? Value(email) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

    await (_db.update(_db.users)..where((t) => t.id.equals(currentUser.id)))
        .write(companion);

    if (currencyCode != null) {
      await _storage.saveCurrency(currencyCode);
    }
    if (themePreference != null) {
      await _storage.saveTheme(themePreference);
    }
    if (biometricEnabled != null) {
      await _storage.setBiometricEnabled(biometricEnabled);
    }
    if (fullName != null) {
      await _storage.saveUserName(fullName);
    }
    if (email != null) {
      await _storage.saveUserEmail(email);
    }
  }
}
