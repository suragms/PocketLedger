import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/core/database/app_database.dart';
import 'package:pocket_ledger/core/services/secure_storage_service.dart';
import 'package:pocket_ledger/features/auth/data/repositories/auth_repository_impl.dart';

class MockSecureStorageService extends SecureStorageService {
  final Map<String, String> _cache = {};

  @override
  Future<void> saveToken(String token) async {
    _cache['auth_token'] = token;
  }

  @override
  Future<String?> getToken() async {
    return _cache['auth_token'];
  }

  @override
  Future<void> saveUserEmail(String email) async {
    _cache['user_email'] = email;
  }

  @override
  Future<String?> getUserEmail() async {
    return _cache['user_email'];
  }

  @override
  Future<void> saveUserName(String name) async {
    _cache['user_name'] = name;
  }

  @override
  Future<String?> getUserName() async {
    return _cache['user_name'];
  }

  @override
  Future<void> saveCurrency(String currencyCode) async {
    _cache['currency_code'] = currencyCode;
  }

  @override
  Future<String> getCurrency() async {
    return _cache['currency_code'] ?? 'INR';
  }

  @override
  Future<void> saveTheme(String theme) async {
    _cache['theme_preference'] = theme;
  }

  @override
  Future<String> getTheme() async {
    return _cache['theme_preference'] ?? 'system';
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    _cache['biometric_enabled'] = enabled.toString();
  }

  @override
  Future<bool> isBiometricEnabled() async {
    return _cache['biometric_enabled'] == 'true';
  }

  @override
  Future<void> clearSession({bool deleteCache = false}) async {
    _cache.remove('auth_token');
    if (deleteCache) {
      _cache.clear();
    }
  }
}

void main() {
  group('AuthRepositoryImpl Integration Tests with In-Memory DB', () {
    late AppDatabase database;
    late MockSecureStorageService storage;
    late AuthRepositoryImpl authRepository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      storage = MockSecureStorageService();
      authRepository = AuthRepositoryImpl(database, storage);
    });

    tearDown(() async {
      await database.close();
    });

    test('User registration should succeed and write to local database', () async {
      final user = await authRepository.register(
        'Jane Doe',
        'jane@example.com',
        'password123',
      );

      expect(user.fullName, 'Jane Doe');
      expect(user.email, 'jane@example.com');
      expect(await storage.getToken(), isNotNull);
      expect(await storage.getUserEmail(), 'jane@example.com');
    });

    test('Duplicate user registration should throw exception', () async {
      await authRepository.register(
        'Jane Doe',
        'jane@example.com',
        'password123',
      );

      expect(
        () => authRepository.register('Jane M', 'jane@example.com', 'pwd12'),
        throwsException,
      );
    });

    test('User login with valid details should succeed', () async {
      await authRepository.register(
        'Jane Doe',
        'jane@example.com',
        'password123',
      );

      // Clear session to simulate fresh login
      await authRepository.logout();
      expect(await storage.getToken(), isNull);

      final loggedInUser = await authRepository.login('jane@example.com', 'password123');
      expect(loggedInUser.fullName, 'Jane Doe');
      expect(await storage.getToken(), isNotNull);
    });

    test('User login with invalid details should throw exception', () async {
      await authRepository.register(
        'Jane Doe',
        'jane@example.com',
        'password123',
      );

      expect(
        () => authRepository.login('jane@example.com', 'wrong_password'),
        throwsException,
      );
    });
  });
}
