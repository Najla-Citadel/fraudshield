import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScanHistoryItem {
  final String content;
  final String riskLevel; // 'low', 'medium', 'high'
  final DateTime timestamp;

  ScanHistoryItem({
    required this.content,
    required this.riskLevel,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        'riskLevel': riskLevel,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) => ScanHistoryItem(
        content: json['content'],
        riskLevel: json['riskLevel'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class ScanHistoryService {
  static const String _key = 'qr_scan_history';

  static Future<List<ScanHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => ScanHistoryItem.fromJson(e)).toList();
  }

  static Future<void> addToHistory(ScanHistoryItem item) async {
    final history = await getHistory();
    
    // Check for duplicates (same content within last minute) to avoid spam
    // Or just insert at top
    history.insert(0, item);

    // Limit to last 50 items
    if (history.length > 50) {
      history.removeLast();
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
