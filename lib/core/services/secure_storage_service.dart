import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  // Auth Token
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: AppConstants.keyToken, value: token);
    } catch (_) {}
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: AppConstants.keyToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: AppConstants.keyToken);
    } catch (_) {}
  }

  // User Email
  Future<void> saveUserEmail(String email) async {
    try {
      await _storage.write(key: AppConstants.keyUserEmail, value: email);
    } catch (_) {}
  }

  Future<String?> getUserEmail() async {
    try {
      return await _storage.read(key: AppConstants.keyUserEmail);
    } catch (_) {
      return null;
    }
  }

  // User Name
  Future<void> saveUserName(String name) async {
    try {
      await _storage.write(key: AppConstants.keyUserName, value: name);
    } catch (_) {}
  }

  Future<String?> getUserName() async {
    try {
      return await _storage.read(key: AppConstants.keyUserName);
    } catch (_) {
      return null;
    }
  }

  // Biometrics
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(key: AppConstants.keyBiometricEnabled, value: enabled.toString());
    } catch (_) {}
  }

  Future<bool> isBiometricEnabled() async {
    try {
      final val = await _storage.read(key: AppConstants.keyBiometricEnabled);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  // Currency Preferences (default: INR)
  Future<void> saveCurrency(String currencyCode) async {
    try {
      await _storage.write(key: AppConstants.keyCurrency, value: currencyCode);
    } catch (_) {}
  }

  Future<String> getCurrency() async {
    try {
      return await _storage.read(key: AppConstants.keyCurrency) ?? AppConstants.defaultCurrency;
    } catch (_) {
      return AppConstants.defaultCurrency;
    }
  }

  // Theme Preference (default: system)
  Future<void> saveTheme(String theme) async {
    try {
      await _storage.write(key: AppConstants.keyTheme, value: theme);
    } catch (_) {}
  }

  Future<String> getTheme() async {
    try {
      return await _storage.read(key: AppConstants.keyTheme) ?? 'system';
    } catch (_) {
      return 'system';
    }
  }

  // App lock/PIN
  Future<void> savePin(String pin) async {
    try {
      await _storage.write(key: AppConstants.keyPin, value: pin);
    } catch (_) {}
  }

  Future<String?> getPin() async {
    try {
      return await _storage.read(key: AppConstants.keyPin);
    } catch (_) {
      return null;
    }
  }

  Future<void> deletePin() async {
    try {
      await _storage.delete(key: AppConstants.keyPin);
    } catch (_) {}
  }

  // Onboarding status
  Future<void> setOnboarded(bool onboarded) async {
    try {
      await _storage.write(key: AppConstants.keyOnboarded, value: onboarded.toString());
    } catch (_) {}
  }

  Future<bool> isOnboarded() async {
    try {
      final val = await _storage.read(key: AppConstants.keyOnboarded);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  // Clear Session (Logout)
  Future<void> clearSession({bool deleteCache = false}) async {
    try {
      await _storage.delete(key: AppConstants.keyToken);
      if (deleteCache) {
        await _storage.deleteAll();
      }
    } catch (_) {}
  }
}
