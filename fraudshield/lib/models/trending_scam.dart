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
}

class MockScamService {
  static List<TrendingScam> getTrendingScams() {
    return [
      TrendingScam(
        id: '1',
        title: 'Package Delivery Phishing',
        description:
            'Attackers impersonate postal services via SMS to steal credit card details for "unpaid customs fees."',
        badgeText: 'HIGH GROWTH',
        badgeColor: const Color(0xFFF97316), // Orange
        timestamp: 'Updated 2h ago',
        example: const ScamExample(
          sender: 'USPS_Alert:',
          message:
              'Your package ID-92831 has been held at our warehouse due to an incorrect address. Please update here: ',
          link: 'bit.ly/usps-fees-alert',
        ),
        safetyTips: [
          'Official carriers never ask for personal info via SMS links.',
          'Check the URL carefully; look for spelling errors like "ups-delivery-fees.com".',
          'Always track items through the official app or website directly.',
        ],
        isExpanded: true, // Default expanded in mockup
      ),
      TrendingScam(
        id: '2',
        title: 'AI Voice Bank Spoofing',
        description:
            'Scammers use AI to clone voices or spoof bank numbers to request emergency transfers.',
        badgeText: 'CRITICAL ALERT',
        badgeColor: const Color(0xFFEF4444), // Red
        timestamp: 'Updated 5h ago',
        safetyTips: [
          'Hang up and dial your bank\'s official number directly.',
          'Establish a safe word with family members for emergencies.',
          'Do not trust Caller ID implicitly, as it can be easily spoofed.',
        ],
      ),
      TrendingScam(
        id: '3',
        title: 'Marketplace Overpayment',
        description:
            'Fake buyers "overpay" for items using fraudulent checks and ask for the difference back.',
        badgeText: 'EMERGING',
        badgeColor: const Color(0xFF3B82F6), // Blue
        timestamp: 'Updated 1d ago',
        safetyTips: [
          'Never accept overpayment for an item you are selling.',
          'Wait for checks to fully clear before refunding any money.',
          'Prefer secure, platform-native payment methods.',
        ],
      ),
    ];
  }
}
