import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecentCheckItem {
  final String type; // 'Phone', 'URL', 'Bank Acc'
  final String value;
  final DateTime timestamp;

  RecentCheckItem({
    required this.type,
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'value': value,
        'timestamp': timestamp.toIso8601String(),
      };

  factory RecentCheckItem.fromJson(Map<String, dynamic> json) => RecentCheckItem(
        type: json['type'],
        value: json['value'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class RecentChecksService {
  static const String _key = 'recent_fraud_checks';

  static Future<List<RecentCheckItem>> getRecentChecks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => RecentCheckItem.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> addCheck(RecentCheckItem item) async {
    final history = await getRecentChecks();
    
    // Remove if exists to move to top
    history.removeWhere((element) => element.value == item.value && element.type == item.type);
    
    // Insert at top
    history.insert(0, item);

    // Keep only last 10
    if (history.length > 10) {
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
