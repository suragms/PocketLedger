import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';

class SyncService {
  final AppDatabase _db;
  bool _isOnline = true; // Connection simulation state
  Timer? _syncTimer;

  SyncService(this._db) {
    // Poll the sync queue every 15 seconds to simulate background sync
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) => triggerSync());
  }

  void dispose() {
    _syncTimer?.cancel();
  }

  // Toggle online state simulation
  bool get isOnline => _isOnline;
  void setOnline(bool online) {
    _isOnline = online;
    if (online) {
      triggerSync();
    }
  }

  Future<void> triggerSync() async {
    if (!_isOnline) return;

    try {
      final queueItems = await _db.select(_db.syncQueue).get();
      if (queueItems.isEmpty) return;

      for (var item in queueItems) {
        // Process each item in the queue (Retry Queue)
        final success = await _syncEntityToServer(item.entityType, item.entityId, item.operation);
        if (success) {
          // If synced successfully, remove from local queue
          await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(item.id))).go();
        }
      }
    } catch (_) {
      // Retried automatically on the next cycle
    }
  }

  Future<bool> _syncEntityToServer(String type, String id, String operation) async {
    // Simulate API Network call latency
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Simulate success
    return true;
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final service = SyncService(db);
  ref.onDispose(() => service.dispose());
  return service;
});
