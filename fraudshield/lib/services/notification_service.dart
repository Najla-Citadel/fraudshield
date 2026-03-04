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

  void addAlert(Map<String, dynamic> alert) {
    _alerts.insert(0, alert);
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
        if (details.payload == 'voice_scan') {
          onNavigate?.call('/voice-scan', null);
        }
      },
    );
  }

  Future<void> showCallAlert() async {
    const fln.AndroidNotificationDetails androidPlatformChannelSpecifics =
        fln.AndroidNotificationDetails(
      'call_alerts',
      'Call Alerts',
      channelDescription: 'Alerts for suspicious incoming calls',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
      ticker: 'ticker',
    );

    const fln.NotificationDetails platformChannelSpecifics =
        fln.NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      0,
      'Incoming Call Detected',
      'Suspect a scam? Tap to start Safety Scan.',
      platformChannelSpecifics,
      payload: 'voice_scan',
    );
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
