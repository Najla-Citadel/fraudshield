import 'package:phone_state/phone_state.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    hide NotificationVisibility;
import 'notification_service.dart';
import 'api_service.dart';
import 'risk_evaluator.dart';

class CallStateService {
  static final CallStateService instance = CallStateService._internal();
  factory CallStateService() => instance;
  CallStateService._internal();

  DateTime? _callStartTime;
  bool _initialized = false;
  PhoneStateStatus? _lastStatus;
  String? _lastNumber;
  int? _lastScore;
  String? _lastLevel;

  Future<void> init() async {
    if (_initialized) return;
    debugPrint('CallStateService: >>> STARTING INIT <<<');

    // 1. Setup Listener IMMEDIATELY so we don't miss anything during permission flow
    PhoneState.stream.listen((event) async {
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
        _handleIncomingCall(event.number);
      } else if (statusStr == 'OFFHOOK' || statusStr == 'CALL_STARTED') {
        _dismissOverlay();
        _callStartTime = DateTime.now();
        _reportSignal('CALL_ACTIVE', number: event.number);
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
        _lastScore = null;
        _lastLevel = null;

        _reportSignal('CALL_ENDED', duration: duration, number: event.number);
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

        // Ensure we have permission first
        if (!await FlutterOverlayWindow.isPermissionGranted()) {
          debugPrint(
              'CallStateService: System Alert Window permission MISSING. Prompting user...');
          await FlutterOverlayWindow.requestPermission();
          return; // Stop here, user needs to grant permission
        }

        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          overlayTitle: "FraudShield Caller Risk",
          overlayContent: "Detecting scam risk...",
          alignment: OverlayAlignment.center,
          visibility: NotificationVisibility.visibilityPublic,
          flag: OverlayFlag.defaultFlag,
          height: 800, // Fixed height for testing
          width: WindowSize.matchParent,
        );
        debugPrint(
            'CallStateService: FlutterOverlayWindow.showOverlay() called successfully.');

        // Share initial data
        await FlutterOverlayWindow.shareData(initialData);
        debugPrint('CallStateService: initialData shared to overlay.');
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
    _reportSignal('CALL_START', number: number);

    // Step 2 — Risk Lookup
    _fetchAndShowRisk(number);
  }

  Future<void> _fetchAndShowRisk(String? number) async {
    final displayNumber =
        (number == null || number.isEmpty) ? 'Unknown Number' : number;

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

    // Step 2: Live risk lookup
    try {
      final result = await RiskEvaluator.evaluatePayment(
        type: 'phone',
        value: number,
      );

      final riskData = {
        'phoneNumber': number,
        'loading': false,
        'score': result.score,
        'level': result.level,
        'communityReports': result.communityReports,
        'categories': result.categories,
      };

      _lastScore = result.score;
      _lastLevel = result.level;

      debugPrint(
          'CallStateService: Risk lookup done. Score=${result.score} Level=${result.level}');

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
  void simulateRinging(String number) {
    debugPrint('CallStateService: [SIMULATE] Triggering RINGING for $number');
    _handleIncomingCall(number);
  }

  Future<void> _reportSignal(String type,
      {int? duration, String? number}) async {
    try {
      if (!ApiService.instance.isAuthenticated) return;
      await ApiService.instance.reportCallSignal(
        event: type,
        duration: duration,
        incomingNumber: number,
      );
      debugPrint('CallStateService: Reported $type to backend');
    } catch (e) {
      debugPrint('CallStateService: Failed to report $type: $e');
    }
  }
}
