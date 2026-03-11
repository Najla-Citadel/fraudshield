import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer';
import 'api_service.dart';

class ScamScannerResult {
  final int totalAppsScanned;
  final List<RiskyApp> riskyApps;
  final DateTime timestamp;
  final Map<String, dynamic> deviceSignals;

  ScamScannerResult({
    required this.totalAppsScanned,
    required this.riskyApps,
    required this.timestamp,
    this.deviceSignals = const {},
  });

  factory ScamScannerResult.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    if (map['createdAt'] != null) {
      parsedDate = DateTime.parse(map['createdAt'] as String);
    } else {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(
          map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch);
    }

    return ScamScannerResult(
      totalAppsScanned: map['totalAppsScanned'] as int? ?? 0,
      riskyApps: (map['riskyApps'] as List? ?? [])
          .map((app) => RiskyApp.fromMap(Map<String, dynamic>.from(app)))
          .toList(),
      timestamp: parsedDate,
      deviceSignals: Map<String, dynamic>.from(map['deviceSignals'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAppsScanned': totalAppsScanned,
      'riskyApps': riskyApps.map((a) => a.toJson()).toList(),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'deviceSignals': deviceSignals,
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
  final String signature; // Phase 2: Certificate matching
  int scoreAdjustment; // Added to handle global reputation

  RiskyApp({
    required this.name,
    required this.packageName,
    required this.score,
    required this.reasons,
    this.signature = '',
    this.scoreAdjustment = 0,
  });

  factory RiskyApp.fromMap(Map<String, dynamic> map) {
    return RiskyApp(
      name: map['name'] as String? ?? 'Unknown',
      packageName: map['packageName'] as String? ?? 'Unknown',
      score: map['score'] as int? ?? 0,
      reasons: (map['reasons'] as List? ?? []).cast<String>(),
      signature: map['signature'] as String? ?? '',
      scoreAdjustment: map['scoreAdjustment'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'packageName': packageName,
      'score': score,
      'reasons': reasons,
      'signature': signature,
      'scoreAdjustment': scoreAdjustment,
    };
  }
}

class ScamScannerService {
  static const _channel = MethodChannel('com.citadel.fraudshield/scanner');
  static const _progressChannel = EventChannel('com.citadel.fraudshield/scanner_progress');
  static bool _isScanning = false;

  static Stream<Map<String, dynamic>> get progressStream => 
      _progressChannel.receiveBroadcastStream().map((event) => Map<String, dynamic>.from(event));

  static Future<ScamScannerResult> startFullScan() async {
    if (_isScanning) {
      throw Exception('Scan already in progress');
    }
    
    _isScanning = true;
    try {
      final Map<String, dynamic> resultData = Map<String, dynamic>.from(
        await _channel.invokeMethod('startFullScan') as Map,
      );
      if (kDebugMode) {
        print('ScamScanner: Scan data received: $resultData');
      }
      final result = ScamScannerResult.fromMap(resultData);
      
      // Fetch Community Intelligence & Threat Database for detected apps
      if (result.riskyApps.isNotEmpty) {
        try {
          final packages = result.riskyApps.map((a) => a.packageName).toList();
          final appData = result.riskyApps.map((a) => {
            'packageName': a.packageName,
            'signature': a.signature,
          }).toList();

          final futures = await Future.wait([
            ApiService.instance.getAppIntelligence(packages),
            ApiService.instance.checkThreatDatabase(appData),
          ]);
          
          final intel = futures[0];
          final threats = futures[1];
          
          for (var app in result.riskyApps) {
            // 1. Apply threat database matches (Critical flags)
            final threat = threats.firstWhere(
              (t) => (t['packageName'] as String) == app.packageName,
              orElse: () => <String, dynamic>{},
            );
            
            if (threat.isNotEmpty) {
              app.reasons.add('⚠️ Confirmed Threat: ${threat['description']}');
              // Boost score for confirmed threats (negative adjustment means more risk)
              app.scoreAdjustment -= (threat['threatLevel'] as int? ?? 20);
            }

            // 2. Apply community intelligence (Reputation)
            final appIntel = intel.firstWhere(
              (i) => (i['packageName'] as String) == app.packageName,
              orElse: () => <String, dynamic>{},
            );
            
            if (appIntel.isNotEmpty) {
              final adjustment = appIntel['globalScoreAdjustment'] as int? ?? 0;
              app.scoreAdjustment += adjustment;
            }
          }
        } catch (e) {
          log('Failed to fetch app intelligence: $e');
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
    } finally {
      _isScanning = false;
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
