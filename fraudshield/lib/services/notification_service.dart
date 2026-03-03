import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
<<<<<<< HEAD
import 'package:flutter_dotenv/flutter_dotenv.dart';
=======
>>>>>>> dev-ui2
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  IO.Socket? _socket;
  final List<Map<String, dynamic>> _alerts = [];

  List<Map<String, dynamic>> get alerts => List.unmodifiable(_alerts);
<<<<<<< HEAD
  
=======

>>>>>>> dev-ui2
  // Callback to handle navigation when a notification is tapped
  Function(String route, dynamic arguments)? onNavigate;

  Future<void> initialize(String userId) async {
    _setupFirebaseMessaging();
<<<<<<< HEAD
    
    if (_socket != null) return;

    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
    final socketUrl = baseUrl.replaceAll('/api/v1', ''); // Get root URL

    _socket = IO.io(socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .enableAutoConnect()
      .build());
=======

    if (_socket != null) return;

    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:3000/api/v1',
    );
    final socketUrl = baseUrl.replaceAll('/api/v1', ''); // Get root URL

    _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .build());
>>>>>>> dev-ui2

    _socket!.onConnect((_) {
      log('🔌 Socket connected: ${_socket!.id}');
      _socket!.emit('join', userId);
    });

    _socket!.on('alert', (data) {
      log('🚨 New alert received: $data');
      _alerts.insert(0, Map<String, dynamic>.from(data));
      notifyListeners();
<<<<<<< HEAD
      
=======

>>>>>>> dev-ui2
      // We could trigger a local notification here if needed
    });

    _socket!.onDisconnect((_) => log('❌ Socket disconnected'));
  }

  Future<void> _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    log('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      log('FCM Token: $token');
      if (token != null) {
        try {
          // Send token to backend
          await ApiService.instance.subscribeToAlerts(fcmToken: token);
        } catch (e) {
          log('Failed to save FCM token: $e');
        }
      }

      // Handle token refresh
      messaging.onTokenRefresh.listen((newToken) async {
        log('FCM Token Refreshed: $newToken');
        try {
          await ApiService.instance.subscribeToAlerts(fcmToken: newToken);
        } catch (e) {
          log('Failed to save refreshed FCM token: $e');
        }
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log('Got a message whilst in the foreground!');
        log('Message data: ${message.data}');

        if (message.notification != null) {
          log('Message also contained a notification: ${message.notification}');
          final alert = {
            'title': message.notification!.title ?? 'Alert',
            'message': message.notification!.body ?? '',
            'severity': message.data['severity'] ?? 'high',
            'type': message.data['type'],
            'reportId': message.data['reportId'],
          };
          _alerts.insert(0, alert);
          notifyListeners();
        }
      });

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log('A new onMessageOpenedApp event was published!');
        _handleNotificationClick(message);
      });

      // Handle notification taps when app is terminated
      messaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          log('App opened from terminated state via notification');
          _handleNotificationClick(message);
        }
      });
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    final type = message.data['type'];
    final reportId = message.data['reportId'];

    if (type == 'local_alert' && reportId != null) {
      onNavigate?.call('/report-details', {'id': reportId});
    } else if (type == 'trending_alert') {
      onNavigate?.call('/scam-alerts', null);
    }
  }

  void clearAlerts() {
    _alerts.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }
}
