import 'package:flutter/services.dart';
import 'dart:developer';
import 'api_service.dart';

class ScamScannerResult {
  final int totalAppsScanned;
  final List<RiskyApp> riskyApps;
  final DateTime timestamp;

  ScamScannerResult({
    required this.totalAppsScanned,
    required this.riskyApps,
    required this.timestamp,
  });

  factory ScamScannerResult.fromMap(Map<String, dynamic> map) {
    return ScamScannerResult(
      totalAppsScanned: map['totalAppsScanned'] as int? ?? 0,
      riskyApps: (map['riskyApps'] as List? ?? [])
          .map((app) => RiskyApp.fromMap(Map<String, dynamic>.from(app)))
          .toList(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
          map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAppsScanned': totalAppsScanned,
      'riskyApps': riskyApps.map((a) => a.toJson()).toList(),
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory ScamScannerResult.fromJson(Map<String, dynamic> json) {
    return ScamScannerResult.fromMap(json);
  }
}

class RiskyApp {
  final String name;
  final String packageName;
  final int score;
  final List<String> reasons;
  int scoreAdjustment; // Added to handle global reputation

  RiskyApp({
    required this.name,
    required this.packageName,
    required this.score,
    required this.reasons,
    this.scoreAdjustment = 0,
  });

  factory RiskyApp.fromMap(Map<String, dynamic> map) {
    return RiskyApp(
      name: map['name'] as String? ?? 'Unknown',
      packageName: map['packageName'] as String? ?? 'Unknown',
      score: map['score'] as int? ?? 0,
      reasons: (map['reasons'] as List? ?? []).cast<String>(),
      scoreAdjustment: map['scoreAdjustment'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'packageName': packageName,
      'score': score,
      'reasons': reasons,
      'scoreAdjustment': scoreAdjustment,
    };
  }
}

class ScamScannerService {
  static const _channel = MethodChannel('com.citadel.fraudshield/scanner');

  static Future<ScamScannerResult> startFullScan() async {
    try {
      final Map<String, dynamic> resultData = Map<String, dynamic>.from(
        await _channel.invokeMethod('startFullScan') as Map,
      );
      final result = ScamScannerResult.fromMap(resultData);
      
      // Fetch Community Intelligence for detected apps
      if (result.riskyApps.isNotEmpty) {
        try {
          final packages = result.riskyApps.map((a) => a.packageName).toList();
          final intel = await ApiService.instance.getAppIntelligence(packages);
          
          for (var app in result.riskyApps) {
            final appIntel = intel.firstWhere(
              (i) => (i['packageName'] as String) == app.packageName,
              orElse: () => <String, dynamic>{},
            );
            
            if (appIntel.isNotEmpty) {
              final adjustment = appIntel['globalScoreAdjustment'] as int? ?? 0;
              app.scoreAdjustment = adjustment;
            }
          }
        } catch (e) {
          log('Failed to fetch community intelligence: $e');
        }
      }

      // Auto-sync with backend (includes adjustments)
      try {
        await ApiService.instance.saveSecurityScan(result);
      } catch (e) {
        log('Failed to sync scan result with backend: $e');
      }
      
      return result;
    } on PlatformException catch (e) {
      log('Failed to perform full scan: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected error during scan: $e');
      rethrow;
    }
  }
  static Future<bool> uninstallApp(String packageName) async {
    try {
      return await _channel.invokeMethod('uninstallApp', {'packageName': packageName}) as bool;
    } catch (e) {
      log('Failed to trigger uninstall: $e');
      return false;
    }
  }

  static Future<bool> openAppSettings(String packageName) async {
    try {
      return await _channel.invokeMethod('openAppSettings', {'packageName': packageName}) as bool;
    } catch (e) {
      log('Failed to open app settings: $e');
      return false;
    }
  }
}
