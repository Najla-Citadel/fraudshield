import 'package:phone_state/phone_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    hide NotificationVisibility;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/services.dart';
import 'notification_service.dart';
import 'api_service.dart';
import 'risk_evaluator.dart';
import 'scam_number_db.dart';
// Removed: import 'dart:convert';

class CallStateService with ChangeNotifier {
  static final CallStateService instance = CallStateService._internal();
  factory CallStateService() => instance;
  CallStateService._internal();

  DateTime? _callStartTime;
  bool _initialized = false;
  bool _isEnabled = false;
  PhoneStateStatus? _lastStatus;
  String? _lastNumber;
  int? _lastScore;
  String? _lastLevel;
  bool? _inContacts;
  String? _userPhoneNumber;

  bool get isEnabled => _isEnabled;

  static const _attestationChannel =
      MethodChannel('com.citadel.fraudshield/call_attestation');
  static const _callScreeningChannel =
      EventChannel('com.citadel.fraudshield/call_screening');
  static const _systemChannel =
      MethodChannel('com.citadel.fraudshield/system');
  static const _roleChannel =
      MethodChannel('com.citadel.fraudshield/role');

  /// Whether CallScreeningService is active (Android 10+)
  bool _useCallScreeningService = false;

  void setUserPhoneNumber(String? number) {
    _userPhoneNumber = number;
    debugPrint('CallStateService: userPhoneNumber set to $_userPhoneNumber');
  }

  /// Get the Android SDK version at runtime
  Future<int> _getAndroidVersion() async {
    try {
      final version = await _systemChannel.invokeMethod('getAndroidVersion');
      return version ?? 28;
    } catch (e) {
      debugPrint('CallStateService: Failed to get Android version: $e');
      return 28; // Default to Android 9
    }
  }

  /// Check if the app is the default call screening app
  Future<bool> isCallScreeningRoleHeld() async {
    try {
      final androidVersion = await _getAndroidVersion();
      if (androidVersion < 29) return false; // Not supported on Android 9

      final result = await _roleChannel.invokeMethod('isRoleHeld');
      return result ?? false;
    } catch (e) {
      debugPrint('CallStateService: Failed to check call screening role: $e');
      return false;
    }
  }

  /// Request the Call Screening role (shows system dialog)
  Future<bool> requestCallScreeningRole() async {
    try {
      final androidVersion = await _getAndroidVersion();
      if (androidVersion < 29) {
        debugPrint('CallStateService: Call Screening not supported on Android < 10');
        return false;
      }

      final result = await _roleChannel.invokeMethod('requestRole');
      debugPrint('CallStateService: Call Screening role request result: $result');
      return result ?? false;
    } catch (e) {
      debugPrint('CallStateService: Failed to request call screening role: $e');
      return false;
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    debugPrint('CallStateService: >>> STARTING INIT <<<');

    // Load enabled state
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('caller_id_protection_enabled') ?? false;
    debugPrint('CallStateService: Protection enabled state: $_isEnabled');

    // Detect Android version for capability-based call monitoring
    final androidVersion = await _getAndroidVersion();
    _useCallScreeningService = androidVersion >= 29;
    debugPrint(
        'CallStateService: Android API $androidVersion, useCallScreeningService=$_useCallScreeningService');

    // Check if Call Screening role is held (Android 10+)
    if (_useCallScreeningService) {
      final isRoleHeld = await isCallScreeningRoleHeld();
      debugPrint('CallStateService: Call Screening role held: $isRoleHeld');

      if (!isRoleHeld) {
        debugPrint('CallStateService: ⚠️ Call Screening role not held - phone numbers may not be available');
        debugPrint('CallStateService: ℹ️ Navigate to /caller-id-setup to enable');
      }
    }

    // 1a. Android 10+: Use CallScreeningService for incoming call detection
    //     (doesn't require READ_CALL_LOG permission)
    if (_useCallScreeningService) {
      _callScreeningChannel.receiveBroadcastStream().listen(
        (event) async {
          if (!_isEnabled) return;
          if (event is Map && event['event'] == 'CALL_SCREENING') {
            final phoneNumber = event['phoneNumber'] as String?;
            final direction = event['callDirection'] as String?;

            debugPrint(
                'CallStateService: [CALL_SCREENING] Number=$phoneNumber Direction=$direction');

            if (direction == 'INCOMING') {
              _inContacts = await _isNumberInContacts(phoneNumber);
              _handleIncomingCall(phoneNumber);
            }
          }
        },
        onError: (error) {
          debugPrint('CallStateService: CallScreening stream error: $error');
        },
      );
    }

    // 1b. PhoneState listener for call lifecycle events
    //     - Android 10+: Only handles OFFHOOK/DISCONNECTED (call answered/ended)
    //     - Android 9:   Handles everything (RINGING + OFFHOOK + DISCONNECTED)
    PhoneState.stream.listen((event) async {
      if (!_isEnabled) return;
      final statusStr = event.status.name.toUpperCase();

      // Deduplication Logic
      if (event.status == _lastStatus && event.number == _lastNumber) return;

      // Handle the "null number then real number" scenario for same status
      if (event.status == _lastStatus &&
          _lastNumber == null &&
          event.number != null) {
        debugPrint(
            'CallStateService: Status stayed same but NUMBER ARRIVED: ${event.number}');
        if (statusStr == 'RINGING' || statusStr == 'CALL_INCOMING') {
          _lastNumber = event.number;
          // Update data in existing internal and system overlay
          _updateOverlayWithNumber(event.number);
          return;
        }
      }

      _lastStatus = event.status;
      _lastNumber = event.number;

      debugPrint(
          'CallStateService: [STREAM] Status=$statusStr Number=${event.number}');

      if (statusStr == 'RINGING' || statusStr == 'CALL_INCOMING') {
        // On Android 10+, skip RINGING from phone_state (CallScreeningService handles it)
        if (_useCallScreeningService) {
          debugPrint(
              'CallStateService: Skipping RINGING (handled by CallScreeningService)');
          return;
        }
        // Android 9: phone_state handles everything
        _inContacts = await _isNumberInContacts(event.number);
        _handleIncomingCall(event.number);
      } else if (statusStr == 'OFFHOOK' || statusStr == 'CALL_STARTED') {
        _dismissOverlay();
        _callStartTime = DateTime.now();
        _reportSignal('CALL_ACTIVE',
            number: event.number, inContacts: _inContacts);
      } else if (statusStr == 'DISCONNECTED' || statusStr == 'CALL_ENDED') {
        _dismissOverlay();

        // Trigger Post-Call UX if it was a risky call
        if (_lastScore != null && _lastScore! >= 55) {
          final data = {
            'phoneNumber': event.number ?? 'Unknown Number',
            'score': _lastScore,
            'level': _lastLevel,
          };
          NotificationService.instance.showPostCallCheck(data);
          NotificationService.instance.recordRiskyCall(data);

          if (_lastLevel == 'critical') {
            NotificationService.instance.startCoolDown();
          }
        }

        int duration = 0;
        if (_callStartTime != null) {
          duration = DateTime.now().difference(_callStartTime!).inSeconds;
          _callStartTime = null;
        }

        // Reset risk state for the next call
        final currentInContacts = _inContacts;
        _lastScore = null;
        _lastLevel = null;
        _inContacts = null;

        _reportSignal('CALL_ENDED',
            duration: duration,
            number: event.number,
            inContacts: currentInContacts);
      }
    });

    // 2. Request Permissions (Non-blocking as much as possible)
    _requestLaunchPermissions();

    _initialized = true;
    debugPrint('CallStateService: >>> INIT COMPLETED <<<');
  }

  Future<void> startProtection() async {
    if (await FlutterForegroundTask.canDrawOverlays) {
      await FlutterForegroundTask.startService(
        notificationTitle: 'FraudShield Protection Active',
        notificationText: 'Monitoring calls for your safety',
      );
      debugPrint('CallStateService: Foreground Service STARTED');
    }
  }

  Future<void> stopProtection() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
      debugPrint('CallStateService: Foreground Service STOPPED');
    }
  }

  Future<void> setProtectionEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('caller_id_protection_enabled', value);
    _isEnabled = value;
    
    if (value) {
      await startProtection();
    } else {
      await stopProtection();
      await _dismissOverlay();
    }
    
    notifyListeners();
    debugPrint('CallStateService: Protection enabled set to: $value');
  }

  Future<void> _requestLaunchPermissions() async {
    try {
      final statuses = await [
        Permission.phone,
        Permission.contacts,
        Permission.notification,
      ].request();
      debugPrint('CallStateService: Permission Result: $statuses');

      // System Alert Window is critical for showing overlay over dialer
      if (await Permission.systemAlertWindow.isDenied) {
        debugPrint('CallStateService: Requesting System Alert Window...');
        await Permission.systemAlertWindow.request();
      }
    } catch (e) {
      debugPrint('CallStateService: Error requesting permissions: $e');
    }
  }

  Future<void> _dismissOverlay() async {
    NotificationService.instance.dismissCallerRisk();
    if (await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.closeOverlay();
    }
  }

  Future<void> _updateOverlayWithNumber(String? number) async {
    if (number == null || number.isEmpty) return;
    debugPrint(
        'CallStateService: Updating existing overlay with number: $number');

    // Update internal state
    final initialData = {
      'phoneNumber': number,
      'loading': true,
      'score': 0,
      'level': 'low',
      'communityReports': 0,
      'categories': <String>[],
    };
    NotificationService.instance.showCallerRiskScreen(initialData);

    // Update system overlay
    await FlutterOverlayWindow.shareData(initialData);

    // Re-trigger risk lookup with the new number
    _fetchAndShowRisk(number);
  }

  /// Shows the overlay immediately in loading state, then fetches risk data.
  Future<void> _handleIncomingCall(String? number) async {
    final displayNumber =
        (number == null || number.isEmpty) ? 'Unknown Number' : number;

    // Step 1 — Show internal overlay (if app in foreground)
    final initialData = {
      'phoneNumber': displayNumber,
      'loading': true,
      'score': 0,
      'level': 'low',
      'communityReports': 0,
      'categories': <String>[],
    };
    NotificationService.instance.showCallerRiskScreen(initialData);

    // Step 1.5 — Show System Overlay (for dialer visibility)
    try {
      if (!await FlutterOverlayWindow.isActive()) {
        debugPrint('CallStateService: Attempting to launch System Overlay...');

        if (!await Permission.systemAlertWindow.isGranted) {
          debugPrint(
              'CallStateService: System Alert Window permission MISSING. Prompting user...');
          // Use permission_handler to avoid collision crash with notification_listener_service
          await Permission.systemAlertWindow.request();
          debugPrint(
              'CallStateService: No system overlay this call; in-app overlay active.');
        } else {
          await FlutterOverlayWindow.showOverlay(
            enableDrag: false,
            overlayTitle: "FraudShield Caller Risk",
            overlayContent: "Detecting scam risk...",
            alignment: OverlayAlignment.center,
            visibility: NotificationVisibility.visibilityPublic,
            flag: OverlayFlag.focusPointer,
            height: WindowSize.fullCover,
            width: WindowSize.matchParent,
            startPosition: const OverlayPosition(0, 0),
          );
          debugPrint(
              'CallStateService: FlutterOverlayWindow.showOverlay() called successfully.');

          // Small delay to ensure the overlay window is fully started before data arrives
          await Future.delayed(const Duration(milliseconds: 400));

          await FlutterOverlayWindow.shareData(initialData);
          debugPrint('CallStateService: initialData shared to overlay.');
        }
      } else {
        debugPrint('CallStateService: System Overlay is already ACTIVE.');
        await FlutterOverlayWindow.shareData(initialData);
      }
    } catch (e) {
      debugPrint('CallStateService: CRITICAL ERROR launching overlay: $e');
    }

    // Also trigger the system notification (for background/lock screen)
    NotificationService.instance.showCallAlert(number: displayNumber);

    // Report call start to backend
    _reportSignal('CALL_START', number: number, inContacts: _inContacts);

    // Step 2 — Risk Lookup
    _fetchAndShowRisk(number);
  }

  /*Future<bool> _isNumberInContacts(String? number) async {
    if (number == null || number.isEmpty) return false;
    if (!await Permission.contacts.isGranted) {
      await Permission.contacts.request();
    }
    if (!await Permission.contacts.isGranted) return false;

    try {
      if (await FlutterContacts.requestPermission(readonly: true)) {
  final contacts = await FlutterContacts.getContacts(withProperties: true);
  final cleanIncoming = number.replaceAll(RegExp(r'[^0-9]'), '');


        for (final contact in contacts) {
          for (final phone in contact.phones) {
            final cleanPhone = phone.number.replaceAll(RegExp(r'[^0-9]'), '');

            if (cleanPhone.endsWith(cleanIncoming) ||
                cleanIncoming.endsWith(cleanPhone)) {
              debugPrint(
                  'CallStateService: Match found in contacts: ${contact.displayName}');
              return true;
            }
          }
        }
      } else {
        debugPrint('Contacts permission not granted');
      }
    } catch (e) {
  debugPrint('CallStateService: Error checking contacts: $e');
}
    return false;
  }*/

Future<bool> _isNumberInContacts(String? number) async {
  return false;
}
  Future<void> _fetchAndShowRisk(String? number) async {
    final displayNumber =
        (number == null || number.isEmpty) ? 'Unknown Number' : number;

    // Contact Book Bypass
    if (_inContacts == true) {
      debugPrint(
          'CallStateService: Bypassing risk lookup for verified contact');
      final contactData = {
        'phoneNumber': displayNumber,
        'loading': false,
        'score': 0,
        'level': 'low',
        'isVerifiedContact': true,
        'categories': ['Verified Contact'],
      };
      NotificationService.instance.updateCallerRiskData(contactData);
      await FlutterOverlayWindow.shareData(contactData);
      return;
    }
    // Step 1: Unknown number shortcut
    if (number == null || number.isEmpty) {
      final unknownData = {
        'phoneNumber': displayNumber,
        'score': 35,
        'level': 'medium',
        'categories': ['Unknown Caller'],
      };
      NotificationService.instance.updateCallerRiskData(unknownData);
      await FlutterOverlayWindow.shareData(unknownData);
      return;
    }

    // Step 2: Check offline database first (instant response)
    try {
      final offlineRisk = await ScamNumberDb.getRisk(number);
      if (offlineRisk != null) {
        debugPrint(
            'CallStateService: 📱 Offline DB HIT - Score: ${offlineRisk['risk_score']}');

        final riskScore = offlineRisk['risk_score'] as int;
        final level = _getRiskLevel(riskScore);
        final categories = offlineRisk['categories'] as List<dynamic>;

        final offlineData = {
          'phoneNumber': number,
          'loading': false,
          'score': riskScore,
          'level': level,
          'communityReports': offlineRisk['report_count'],
          'categories': categories,
          'source': 'offline',
        };

        // Show offline result immediately
        NotificationService.instance.updateCallerRiskData(offlineData);
        await FlutterOverlayWindow.shareData(offlineData);

        // Update push notification
        NotificationService.instance.showCallAlert(
          number: displayNumber,
          score: riskScore,
          level: level,
          categories: categories.cast<String>(),
        );

        _lastScore = riskScore;
        _lastLevel = level;

        // Still call backend in background for fresh data + STIR/SHAKEN
        _updateRiskInBackground(number, displayNumber);
        return;
      }
    } catch (e) {
      debugPrint('CallStateService: Offline DB lookup failed: $e');
      // Continue with online lookup
    }

    // Step 3: Live risk lookup & Neighbor Spoofing Check
    try {
      final neighborResult = RiskEvaluator.evaluateNeighborSpoofing(
        incomingNumber: displayNumber,
        userPhoneNumber: _userPhoneNumber,
      );

      final result = await RiskEvaluator.evaluatePayment(
        type: 'phone',
        value: number,
      );

      int finalScore = result.score;
      String finalLevel = result.level;
      List<String> finalReasons = List.from(result.categories);

      // Check STIR/SHAKEN Attestation Status
      try {
        final int attestationStatus =
            await _attestationChannel.invokeMethod('getVerificationStatus', {
          'phoneNumber': displayNumber,
        });

        if (attestationStatus == 1) {
          // VERIFICATION_STATUS_PASSED
          finalScore = (finalScore - 20).clamp(0, 100);
          finalReasons.insert(
              0, '✅ Caller Identity Verified by Carrier (STIR/SHAKEN)');
        } else if (attestationStatus == 2) {
          // VERIFICATION_STATUS_FAILED
          finalScore = (finalScore + 30).clamp(0, 100);
          finalReasons.insert(0,
              '❌ Caller Identity Failed Carrier Verification (Spoofing Risk)');
        }
      } catch (e) {
        debugPrint('CallStateService: Failed to get STIR/SHAKEN status: $e');
      }

      // Merge Neighbor Spoofing Risk if it's higher
      if (neighborResult.score > 0) {
        if (neighborResult.score > finalScore) {
          finalScore = neighborResult.score;
        }
        finalReasons.insertAll(0, neighborResult.reasons);
      }

      // Recalculate level based on exact score after adjustments
      if (finalScore >= 80) {
        finalLevel = 'critical';
      } else if (finalScore >= 55)
        finalLevel = 'high';
      else if (finalScore >= 30)
        finalLevel = 'medium';
      else
        finalLevel = 'low';

      final riskData = {
        'phoneNumber': number,
        'loading': false,
        'score': finalScore,
        'level': finalLevel,
        'communityReports': result.communityReports,
        'categories': finalReasons,
      };

      _lastScore = finalScore;
      _lastLevel = finalLevel;

      debugPrint(
          'CallStateService: Risk lookup done. Score=$finalScore Level=$finalLevel');

      // Shared to both UI systems
      NotificationService.instance.updateCallerRiskData(riskData);
      await FlutterOverlayWindow.shareData(riskData);

      // Update the push notification with real-time risk info
      NotificationService.instance.showCallAlert(
        number: displayNumber,
        score: result.score,
        level: result.level,
        categories: result.categories,
      );
    } catch (e) {
      debugPrint('CallStateService: Risk evaluation error: $e');
      final errorData = {
        'phoneNumber': displayNumber,
        'loading': false,
        'error': 'Risk lookup failed',
      };
      NotificationService.instance.updateCallerRiskData(errorData);
      await FlutterOverlayWindow.shareData(errorData);
    }
  }

  /// Manually trigger the ringing state for UI testing/simulation.
  /// Only available in debug builds (guarded by kDebugMode).
  void simulateRinging(String number) {
    if (!kDebugMode) {
      debugPrint('CallStateService: simulateRinging only available in DEBUG mode');
      return;
    }
    debugPrint('CallStateService: [SIMULATE] Triggering RINGING for $number');
    _handleIncomingCall(number);
  }

  Future<void> _reportSignal(String type,
      {int? duration, String? number, bool? inContacts}) async {
    try {
      if (!ApiService.instance.isAuthenticated) return;
      await ApiService.instance.reportCallSignal(
        event: type,
        duration: duration,
        incomingNumber: number,
        inContacts: inContacts,
      );
      debugPrint('CallStateService: Reported $type to backend');
    } catch (e) {
      debugPrint('CallStateService: Failed to report $type: $e');
    }
  }

  /// Convert risk score to level string
  String _getRiskLevel(int score) {
    if (score >= 80) return 'critical';
    if (score >= 55) return 'high';
    if (score >= 30) return 'medium';
    return 'low';
  }

  /// Update risk data in background (after showing offline result)
  /// This ensures fresh data with STIR/SHAKEN verification
  Future<void> _updateRiskInBackground(String number, String displayNumber) async {
    try {
      debugPrint('CallStateService: 🔄 Updating risk in background...');

      final neighborResult = RiskEvaluator.evaluateNeighborSpoofing(
        incomingNumber: displayNumber,
        userPhoneNumber: _userPhoneNumber,
      );

      final result = await RiskEvaluator.evaluatePayment(
        type: 'phone',
        value: number,
      );

      int finalScore = result.score;
      String finalLevel = result.level;
      List<String> finalReasons = List.from(result.categories);

      // Check STIR/SHAKEN Attestation Status
      try {
        final int attestationStatus =
            await _attestationChannel.invokeMethod('getVerificationStatus', {
          'phoneNumber': displayNumber,
        });

        if (attestationStatus == 1) {
          finalScore = (finalScore - 20).clamp(0, 100);
          finalReasons.insert(
              0, '✅ Caller Identity Verified by Carrier (STIR/SHAKEN)');
        } else if (attestationStatus == 2) {
          finalScore = (finalScore + 30).clamp(0, 100);
          finalReasons.insert(0,
              '❌ Caller Identity Failed Carrier Verification (Spoofing Risk)');
        }
      } catch (e) {
        debugPrint('CallStateService: Failed to get STIR/SHAKEN status: $e');
      }

      // Merge Neighbor Spoofing Risk if it's higher
      if (neighborResult.score > 0) {
        if (neighborResult.score > finalScore) {
          finalScore = neighborResult.score;
        }
        finalReasons.insertAll(0, neighborResult.reasons);
      }

      // Recalculate level
      finalLevel = _getRiskLevel(finalScore);

      // Only update if score changed significantly (>10 points)
      if ((_lastScore == null || (finalScore - _lastScore!).abs() > 10)) {
        debugPrint('CallStateService: ⚡ Significant change detected, updating overlay');

        final riskData = {
          'phoneNumber': number,
          'loading': false,
          'score': finalScore,
          'level': finalLevel,
          'communityReports': result.communityReports,
          'categories': finalReasons,
          'source': 'online',
        };

        _lastScore = finalScore;
        _lastLevel = finalLevel;

        NotificationService.instance.updateCallerRiskData(riskData);
        await FlutterOverlayWindow.shareData(riskData);
      } else {
        debugPrint('CallStateService: No significant change, keeping offline result');
      }
    } catch (e) {
      debugPrint('CallStateService: Background update failed: $e');
    }
  }
}
