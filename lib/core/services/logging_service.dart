import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoggingService {
  void logInfo(String message) {
    developer.log('[INFO] PocketLedger: $message', name: 'PocketLedger');
  }

  void logError(String message, [dynamic error, StackTrace? stack]) {
    developer.log('[ERROR] PocketLedger: $message', name: 'PocketLedger', error: error, stackTrace: stack);
    
    // Simulates Firebase Crashlytics crash reporting
    developer.log('[CRASHLYTICS] Logged crash event: $message', name: 'PocketLedger');
  }

  void logEvent(String eventName, [Map<String, dynamic>? parameters]) {
    // Simulates Firebase Analytics tracking
    developer.log('[ANALYTICS] Event Logged: $eventName, parameters: $parameters', name: 'PocketLedger');
  }
}

final loggingServiceProvider = Provider<LoggingService>((ref) {
  return LoggingService();
});
