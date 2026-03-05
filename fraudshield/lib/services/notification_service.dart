import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;

class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  Function(String, dynamic)? onNavigate;
  final List<dynamic> _alerts = [];
  List<dynamic> get alerts => _alerts;

  Map<String, dynamic>? _activeIntervention;
  Map<String, dynamic>? get activeIntervention => _activeIntervention;

  DateTime? _lastRiskyCallTime;
  Map<String, dynamic>? _lastRiskyCallData;
  DateTime? get lastRiskyCallTime => _lastRiskyCallTime;

  // ── Caller Risk State ────────────────────────────────
  Map<String, dynamic>? _activeCallerRisk;
  Map<String, dynamic>? get activeCallerRisk => _activeCallerRisk;

  void showCallerRiskScreen(Map<String, dynamic> data) {
    _activeCallerRisk = data;
    notifyListeners();
  }

  void updateCallerRiskData(Map<String, dynamic> data) {
    if (_activeCallerRisk != null) {
      _activeCallerRisk = {..._activeCallerRisk!, ...data, 'loading': false};
      notifyListeners();
    }
  }

  void dismissCallerRisk() {
    _activeCallerRisk = null;
    notifyListeners();
  }

  void addAlert(Map<String, dynamic> alert) {
    _alerts.insert(0, alert);
    notifyListeners();
  }

  void showMacauIntervention(Map<String, dynamic> evaluation) {
    _activeIntervention = evaluation;
    notifyListeners();
  }

  void dismissIntervention() {
    _activeIntervention = null;
    notifyListeners();
  }

  void recordRiskyCall(Map<String, dynamic> data) {
    _lastRiskyCallTime = DateTime.now();
    _lastRiskyCallData = data;
    debugPrint(
        'NotificationService: Recorded risky call for behavioral tracking at $_lastRiskyCallTime');
  }

  bool isCheckRequiredForSensitiveAction() {
    if (_lastRiskyCallTime == null) return false;
    final diff = DateTime.now().difference(_lastRiskyCallTime!);
    // Macau Scam pattern typically occurs within 2-5 minutes of call ending
    return diff.inMinutes <= 2;
  }

  void triggerMacauWarning() {
    if (_lastRiskyCallData != null) {
      showMacauIntervention({
        ..._lastRiskyCallData!,
        'type': 'behavioral_correlation',
        'reason':
            'Detected sensitive action immediately after a high-risk call.',
        'reasons': [
          'Macau Scam Pattern Detected',
          'High-urgency call followed by financial action'
        ],
      });
    }
  }

  // ── Post-Call Safety Check State ──────────────────────
  Map<String, dynamic>? _postCallCheck;
  Map<String, dynamic>? get postCallCheck => _postCallCheck;

  void showPostCallCheck(Map<String, dynamic> data) {
    _postCallCheck = data;
    notifyListeners();
  }

  void dismissPostCallCheck() {
    _postCallCheck = null;
    notifyListeners();
  }

  // ── Cool-down Timer State ─────────────────────────────
  bool _coolDownActive = false;
  bool get coolDownActive => _coolDownActive;

  DateTime? _coolDownEndsAt;
  DateTime? get coolDownEndsAt => _coolDownEndsAt;

  void startCoolDown() {
    _coolDownActive = true;
    _coolDownEndsAt = DateTime.now().add(const Duration(minutes: 10));
    notifyListeners();
  }

  void dismissCoolDown() {
    _coolDownActive = false;
    _coolDownEndsAt = null;
    notifyListeners();
  }

  void clearAlerts() {
    _alerts.clear();
    notifyListeners();
  }

  /// Original initialize method called by AuthProvider
  Future<void> initialize(String userId) async {
    debugPrint('NotificationService: Initializing for user $userId');
    // Original logic for registering push tokens/etc would go here
  }

  final fln.FlutterLocalNotificationsPlugin _notificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    const fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (fln.NotificationResponse details) {
        if (details.payload == 'voice_scan' ||
            details.payload == 'voice_scan_auto_start') {
          onNavigate?.call(
            '/voice-scan',
            details.payload == 'voice_scan_auto_start'
                ? {'autoStart': true}
                : null,
          );
        }
      },
    );
  }

  Future<void> showCallAlert({
    required String number,
    int? score,
    String? level,
    List<String>? categories,
  }) async {
    const fln.AndroidNotificationDetails androidPlatformChannelSpecifics =
        fln.AndroidNotificationDetails(
      'call_alerts',
      'Call Alerts',
      channelDescription: 'Alerts for suspicious incoming calls',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
      ticker: 'ticker',
      actions: <fln.AndroidNotificationAction>[
        fln.AndroidNotificationAction(
          'action_record',
          'Record & Analyze',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const fln.NotificationDetails platformChannelSpecifics =
        fln.NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    String title = 'Incoming Call: $number';
    String body = 'Suspect a scam? Tap to start Safety Scan.';

    if (level == 'critical' || level == 'high') {
      title = '🚨 Scam Warning: $number';
      body = 'Risk Score: $score/100. Do not provide OTPs or transfer money.';
      if (categories != null && categories.isNotEmpty) {
        body = '⚠️ ${categories.first}: Risk Score $score. Do not answer.';
      }
    } else if (level == 'medium') {
      title = '⚠️ Suspicious Call: $number';
    } else if (level == 'low') {
      title = '✅ Safe Call: $number';
      body = 'Checks passed. Tap to enable voice recording.';
    }

    await _notificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'voice_scan_auto_start',
    );
    debugPrint(
        'NotificationService: Call alert shown successfully. Level: $level');
  }

  Future<void> showNotification(
      {required String title, required String body}) async {
    const fln.AndroidNotificationDetails androidPlatformChannelSpecifics =
        fln.AndroidNotificationDetails(
      'generic_alerts',
      'Generic Alerts',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
    );

    const fln.NotificationDetails platformChannelSpecifics =
        fln.NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
