import 'package:shared_preferences/shared_preferences.dart';
import 'scam_number_db.dart';
import 'api_service.dart';

/// ScamSyncService handles background synchronization of scam numbers
/// from the backend API to the local SQLite database for offline protection.
class ScamSyncService {
  static const String _lastSyncKey = 'last_scam_sync';
  static const String _syncCountKey = 'scam_sync_count';

  /// Perform full sync from backend to local database
  static Future<bool> performSync() async {
    try {
      print('🔄 ScamSync: Starting sync...');
      final startTime = DateTime.now();

      // Get last sync timestamp
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString(_lastSyncKey);

      // Build query parameters for incremental sync
      final queryParams = lastSync != null
          ? '?lastSyncedAt=$lastSync'
          : ''; // First sync - get all numbers

      // Call backend sync endpoint
      final response = await ApiService.instance.get(
        '/reports/scam-numbers/sync$queryParams',
      );

      if (response == null) {
        print('⚠️ ScamSync: No response from server');
        return false;
      }

      // Extract scam numbers from response
      final numbers = response['numbers'] as List? ?? [];
      final syncedAt = response['syncedAt'] as String?;

      print('📊 ScamSync: Received ${numbers.length} numbers from server');

      if (numbers.isEmpty && lastSync != null) {
        print('✅ ScamSync: Already up to date, no new numbers');
        return true;
      }

      // Batch insert to local database
      final numbersList = numbers.cast<Map<String, dynamic>>();
      await ScamNumberDb.batchInsert(numbersList);

      // Cleanup old entries (older than 90 days)
      await ScamNumberDb.cleanupOldEntries();

      // Update last sync timestamp
      if (syncedAt != null) {
        await prefs.setString(_lastSyncKey, syncedAt);
      }

      // Update sync count for stats
      final syncCount = prefs.getInt(_syncCountKey) ?? 0;
      await prefs.setInt(_syncCountKey, syncCount + 1);

      // Get database stats
      final stats = await ScamNumberDb.getStats();

      final duration = DateTime.now().difference(startTime);
      print('✅ ScamSync: Completed in ${duration.inMilliseconds}ms');
      print('📊 ScamSync: Database stats - Total: ${stats['total']}, High Risk: ${stats['high_risk']}, Critical: ${stats['critical']}');

      return true;
    } catch (e) {
      print('❌ ScamSync: Failed - $e');
      return false;
    }
  }

  /// Get last sync timestamp
  static Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncString = prefs.getString(_lastSyncKey);
      if (lastSyncString != null) {
        return DateTime.parse(lastSyncString);
      }
    } catch (e) {
      print('⚠️ ScamSync: Failed to get last sync time: $e');
    }
    return null;
  }

  /// Get sync statistics
  static Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = await getLastSyncTime();
      final syncCount = prefs.getInt(_syncCountKey) ?? 0;
      final dbStats = await ScamNumberDb.getStats();

      return {
        'lastSyncTime': lastSync?.toIso8601String(),
        'totalSyncs': syncCount,
        'cachedNumbers': dbStats['total'],
        'highRiskNumbers': dbStats['high_risk'],
        'criticalNumbers': dbStats['critical'],
      };
    } catch (e) {
      print('⚠️ ScamSync: Failed to get stats: $e');
      return {};
    }
  }

  /// Force immediate sync (for manual trigger)
  static Future<bool> forceSyncNow() async {
    print('🔄 ScamSync: Force sync requested');
    return performSync();
  }

  /// Reset sync state (for testing/debugging)
  static Future<void> resetSyncState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSyncKey);
      await prefs.remove(_syncCountKey);
      await ScamNumberDb.clearAll();
      print('🧹 ScamSync: Reset complete');
    } catch (e) {
      print('⚠️ ScamSync: Failed to reset: $e');
    }
  }

  /// Check if sync is needed (for manual checks)
  static Future<bool> isSyncNeeded() async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true; // Never synced

    // Check if more than 12 hours since last sync
    final hoursSinceSync = DateTime.now().difference(lastSync).inHours;
    return hoursSinceSync >= 12;
  }
}
