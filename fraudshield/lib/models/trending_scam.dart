import 'package:flutter/material.dart';

class ScamExample {
  final String sender;
  final String message;
  final String link;

  const ScamExample({
    required this.sender,
    required this.message,
    required this.link,
  });

  factory ScamExample.fromJson(Map<String, dynamic> json) {
    return ScamExample(
      sender: json['sender'] as String? ?? 'Unknown',
      message: json['message'] as String? ?? '',
      link: json['link'] as String? ?? '',
    );
  }
}

class TrendingScam {
  final String id;
  final String title;
  final String description;
  final String badgeText;
  final Color badgeColor;
  final String timestamp;
  final ScamExample? example;
  final List<String> safetyTips;
  bool isExpanded;

  TrendingScam({
    required this.id,
    required this.title,
    required this.description,
    required this.badgeText,
    required this.badgeColor,
    required this.timestamp,
    this.example,
    this.safetyTips = const [],
    this.isExpanded = false,
  });

  factory TrendingScam.fromJson(Map<String, dynamic> json) {
    ScamExample? parsedExample;
    if (json['example'] != null) {
      parsedExample = ScamExample.fromJson(json['example']);
    }

    List<String> parsedSafetyTips = [];
    if (json['safetyTips'] != null && json['safetyTips'] is List) {
      parsedSafetyTips = List<String>.from(json['safetyTips']);
    }

    Color badgeColor = Colors.grey;
    if (json['badgeColor'] != null && json['badgeColor'].toString().startsWith('#')) {
      final hexString = json['badgeColor'].toString().replaceAll('#', '0xFF');
      badgeColor = Color(int.tryParse(hexString) ?? 0xFF9E9E9E);
    }

    return TrendingScam(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Scam',
      description: json['description']?.toString() ?? '',
      badgeText: json['badgeText']?.toString() ?? 'ALERT',
      badgeColor: badgeColor,
      timestamp: json['timestamp']?.toString() ?? '',
      example: parsedExample,
      safetyTips: parsedSafetyTips,
      isExpanded: json['isExpanded'] == true,
    );
  }
}
