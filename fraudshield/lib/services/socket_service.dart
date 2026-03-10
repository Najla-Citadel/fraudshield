import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';
import 'package:flutter/foundation.dart';

class SocketService {
  static final SocketService instance = SocketService._internal();
  SocketService._internal();

  IO.Socket? socket;

  void init() {
    // Socket.io usually runs on the root path, not /api/v1
    String socketUrl = ApiService.baseUrl.replaceAll('/api/v1', '');
    if (socketUrl.isEmpty) {
      debugPrint('Socket notification: Base URL empty, socket disabled');
      return;
    }

    debugPrint('Initializing Socket.io at: $socketUrl');

    socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket!.onConnect((_) {
      debugPrint('✅ Connected to Socket.io server');
    });

    socket!.onDisconnect((_) {
      debugPrint('❌ Disconnected from Socket.io server');
    });

    socket!.onConnectError((err) {
      debugPrint('⚠️ Socket Connection Error: $err');
    });

    socket!.connect();
  }

  void joinReport(String reportId) {
    debugPrint('Joining socket room for report: $reportId');
    socket?.emit('join_report', reportId);
  }

  void leaveReport(String reportId) {
    debugPrint('Leaving socket room for report: $reportId');
    socket?.emit('leave_report', reportId);
  }

  void onNewComment(Function(Map<String, dynamic>) callback) {
    socket?.on('new_comment', (data) {
      if (data != null) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void onNewPublicReport(Function(Map<String, dynamic>) callback) {
    socket?.on('new_public_report', (data) {
      if (data != null) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void dispose() {
    socket?.disconnect();
    socket?.dispose();
  }
}
