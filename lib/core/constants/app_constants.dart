class AppConstants {
  // Asset Paths
  static const String logoPath = 'assets/logo.png';
  
  // Secure Storage keys
  static const String keyToken = 'auth_token';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_name';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyCurrency = 'currency_code';
  static const String keyTheme = 'theme_preference';
  static const String keyPin = 'app_pin';
  static const String keyOnboarded = 'has_completed_onboarding';
  
  // Currencies
  static const String defaultCurrency = 'INR';
  static const List<String> supportedCurrencies = ['INR', 'USD', 'EUR', 'GBP'];
}
