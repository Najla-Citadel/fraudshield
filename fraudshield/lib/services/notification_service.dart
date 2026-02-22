import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  IO.Socket? _socket;
  final List<Map<String, dynamic>> _alerts = [];

  List<Map<String, dynamic>> get alerts => List.unmodifiable(_alerts);

  Future<void> initialize(String userId) async {
    _setupFirebaseMessaging();
    
    if (_socket != null) return;

    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
    final socketUrl = baseUrl.replaceAll('/api/v1', ''); // Get root URL

    _socket = IO.io(socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .enableAutoConnect()
      .build());

    _socket!.onConnect((_) {
      log('🔌 Socket connected: ${_socket!.id}');
      _socket!.emit('join', userId);
    });

    _socket!.on('alert', (data) {
      log('🚨 New alert received: $data');
      _alerts.insert(0, Map<String, dynamic>.from(data));
      notifyListeners();
      
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
          _alerts.insert(0, {
            'title': message.notification!.title ?? 'Alert',
            'message': message.notification!.body ?? '',
            'severity': message.data['severity'] ?? 'high',
          });
          notifyListeners();
        }
      });
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
