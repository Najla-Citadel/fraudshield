import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// ScamNumberDb provides offline storage for high-risk scam phone numbers.
/// This enables instant risk detection even without internet connectivity.
class ScamNumberDb {
  static Database? _database;

  /// Singleton database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  /// Initialize the database with schema
  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'scam_numbers.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE scam_numbers (
            phone_number TEXT PRIMARY KEY,
            risk_score INTEGER NOT NULL,
            report_count INTEGER NOT NULL,
            verified_count INTEGER NOT NULL,
            categories TEXT,
            last_reported TEXT NOT NULL,
            synced_at TEXT NOT NULL
          )
        ''');

        // Index for efficient cleanup queries
        await db.execute(
          'CREATE INDEX idx_last_reported ON scam_numbers(last_reported)',
        );

        print('✅ ScamNumberDb: Database created successfully');
      },
    );
  }

  /// Get risk information for a specific phone number
  /// Returns null if number not found in offline cache
  static Future<Map<String, dynamic>?> getRisk(String phoneNumber) async {
    try {
      final db = await database;
      final normalizedNumber = _normalizePhoneNumber(phoneNumber);

      final results = await db.query(
        'scam_numbers',
        where: 'phone_number = ?',
        whereArgs: [normalizedNumber],
      );

      if (results.isEmpty) {
        return null;
      }

      final result = results.first;

      // Parse categories from JSON string
      List<dynamic> categories = [];
      if (result['categories'] != null && result['categories'] != '') {
        try {
          categories = jsonDecode(result['categories'] as String);
        } catch (e) {
          print('⚠️ ScamNumberDb: Failed to parse categories: $e');
        }
      }

      return {
        'phone_number': result['phone_number'],
        'risk_score': result['risk_score'],
        'report_count': result['report_count'],
        'verified_count': result['verified_count'],
        'categories': categories,
        'last_reported': result['last_reported'],
        'synced_at': result['synced_at'],
      };
    } catch (e) {
      print('⚠️ ScamNumberDb: Failed to get risk for $phoneNumber: $e');
      return null;
    }
  }

  /// Insert or update a single scam number
  static Future<void> insertOrUpdate(Map<String, dynamic> number) async {
    try {
      final db = await database;
      await db.insert(
        'scam_numbers',
        {
          'phone_number': _normalizePhoneNumber(number['phoneNumber']),
          'risk_score': number['riskScore'],
          'report_count': number['reportCount'],
          'verified_count': number['verifiedCount'],
          'categories': number['categories'] is String
              ? number['categories']
              : jsonEncode(number['categories'] ?? []),
          'last_reported': number['lastReported'] is String
              ? number['lastReported']
              : DateTime.now().toIso8601String(),
          'synced_at': number['updatedAt'] ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('⚠️ ScamNumberDb: Failed to insert/update number: $e');
    }
  }

  /// Batch insert/update multiple scam numbers (used during sync)
  static Future<void> batchInsert(List<Map<String, dynamic>> numbers) async {
    if (numbers.isEmpty) return;

    try {
      final db = await database;
      final batch = db.batch();

      for (var number in numbers) {
        batch.insert(
          'scam_numbers',
          {
            'phone_number': _normalizePhoneNumber(number['phoneNumber']),
            'risk_score': number['riskScore'],
            'report_count': number['reportCount'],
            'verified_count': number['verifiedCount'],
            'categories': number['categories'] is String
                ? number['categories']
                : jsonEncode(number['categories'] ?? []),
            'last_reported': number['lastReported'],
            'synced_at': number['updatedAt'] ?? DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      print('✅ ScamNumberDb: Batch inserted ${numbers.length} numbers');
    } catch (e) {
      print('⚠️ ScamNumberDb: Batch insert failed: $e');
    }
  }

  /// Remove entries older than 90 days
  static Future<void> cleanupOldEntries() async {
    try {
      final db = await database;
      final cutoff = DateTime.now().subtract(const Duration(days: 90));
      final cutoffString = cutoff.toIso8601String();

      final count = await db.delete(
        'scam_numbers',
        where: 'last_reported < ?',
        whereArgs: [cutoffString],
      );

      if (count > 0) {
        print('🧹 ScamNumberDb: Cleaned up $count old entries (>90 days)');
      }
    } catch (e) {
      print('⚠️ ScamNumberDb: Cleanup failed: $e');
    }
  }

  /// Get cache statistics (for debugging)
  static Future<Map<String, int>> getStats() async {
    try {
      final db = await database;

      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM scam_numbers');
      final highRiskResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM scam_numbers WHERE risk_score >= 55',
      );
      final criticalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM scam_numbers WHERE risk_score >= 80',
      );

      return {
        'total': (totalResult.first['count'] as int?) ?? 0,
        'high_risk': (highRiskResult.first['count'] as int?) ?? 0,
        'critical': (criticalResult.first['count'] as int?) ?? 0,
      };
    } catch (e) {
      print('⚠️ ScamNumberDb: Failed to get stats: $e');
      return {'total': 0, 'high_risk': 0, 'critical': 0};
    }
  }

  /// Clear all cached numbers (for testing/debugging)
  static Future<void> clearAll() async {
    try {
      final db = await database;
      await db.delete('scam_numbers');
      print('🧹 ScamNumberDb: Cleared all cached numbers');
    } catch (e) {
      print('⚠️ ScamNumberDb: Failed to clear database: $e');
    }
  }

  /// Normalize phone number to a consistent format
  /// Converts to international format with +60 prefix for Malaysian numbers
  static String _normalizePhoneNumber(String phoneNumber) {
    // Remove all spaces, dashes, and brackets
    String normalized = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Convert 01X to +601X (Malaysian format)
    if (normalized.startsWith('01')) {
      normalized = '+60${normalized.substring(1)}';
    }

    // Ensure +60 prefix for numbers starting with 60
    if (normalized.startsWith('60') && !normalized.startsWith('+')) {
      normalized = '+$normalized';
    }

    return normalized;
  }

  /// Close the database connection (used when app terminates)
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('🔒 ScamNumberDb: Database closed');
    }
  }
}
