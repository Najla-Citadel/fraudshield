import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  IO.Socket? _socket;
  final List<Map<String, dynamic>> _alerts = [];

  List<Map<String, dynamic>> get alerts => List.unmodifiable(_alerts);

  void initialize(String userId) {
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
