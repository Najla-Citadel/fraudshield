import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import 'package:intl/intl.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Activity Log',
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: IconButton(
            icon: const Icon(LucideIcons.sliders, size: 20, color: Colors.white),
            onPressed: () {
              // Filter action
            },
          ),
        ),
      ],
      body: Consumer<NotificationService>(
        builder: (context, notificationService, _) {
          final activities = _getAllActivities(notificationService.alerts);
          final grouped = _groupActivities(activities);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final group = grouped.keys.elementAt(index);
              final items = grouped[group]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      group.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  ...items.map((item) => _ActivityCard(item: item)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getAllActivities(List<dynamic> realAlerts) {
    final mockData = [
      {
        'title': 'SMS Phishing Blocked',
        'message':
            'A suspicious message containing a fraudulent banking link was automatically intercepted.',
        'timestamp':
            DateTime.now().subtract(const Duration(hours: 2)).toString(),
        'type': 'danger',
        'icon': LucideIcons.shieldAlert,
      },
      {
        'title': 'System Scan Completed',
        'message':
            'Full device security audit finished. No vulnerabilities or malware found.',
        'timestamp':
            DateTime.now().subtract(const Duration(hours: 5)).toString(),
        'type': 'success',
        'icon': LucideIcons.checkCircle,
      },
      {
        'title': 'Safe Link Verified',
        'message':
            'The link "secure-portal.bank.com" was analyzed and confirmed as authentic.',
        'timestamp':
            DateTime.now().subtract(const Duration(hours: 7)).toString(),
        'type': 'safe',
        'icon': LucideIcons.shieldCheck,
      },
      {
        'title': 'Identity Guard Active',
        'message':
            'Deep web scan completed. Your personal information remains secure.',
        'timestamp': DateTime.now()
            .subtract(const Duration(days: 1, hours: 3))
            .toString(),
        'type': 'info',
        'icon': LucideIcons.fingerprint,
      },
      {
        'title': 'Payment Monitor',
        'message': 'Secure payment channel verified for recent transaction.',
        'timestamp': DateTime.now()
            .subtract(const Duration(days: 1, hours: 5))
            .toString(),
        'type': 'success',
        'icon': LucideIcons.creditCard,
      },
    ];

    return [...realAlerts, ...mockData];
  }

  Map<String, List<Map<String, dynamic>>> _groupActivities(
      List<Map<String, dynamic>> activities) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var activity in activities) {
      final timestampStr = activity['timestamp']?.toString();
      if (timestampStr == null || timestampStr.isEmpty) continue;

      try {
        final date = DateTime.parse(timestampStr);
        final now = DateTime.now();
        String key;

        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          key = 'Today';
        } else if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day - 1) {
          key = 'Yesterday';
        } else {
          key = DateFormat('MMMM d').format(date);
        }

        if (!grouped.containsKey(key)) {
          grouped[key] = [];
        }
        grouped[key]!.add(activity);
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }
    return grouped;
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _ActivityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    Color iconBg;

    switch (item['type']) {
      case 'danger':
        iconColor = Colors.orange;
        iconBg = Colors.orange.withValues(alpha: 0.1);
        break;
      case 'success':
        iconColor = DesignTokens.colors.accentGreen;
        iconBg = DesignTokens.colors.accentGreen.withValues(alpha: 0.1);
        break;
      case 'safe':
        iconColor = Colors.blue;
        iconBg = Colors.blue.withValues(alpha: 0.1);
        break;
      case 'info':
      default:
        iconColor = Colors.blueAccent;
        iconBg = Colors.blueAccent.withValues(alpha: 0.1);
        break;
    }

    final IconData icon = item['icon'] ?? LucideIcons.bell;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.colors.glassDark,
        borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['title'] ?? 'Activity',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(item['timestamp']),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item['message'] ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return '';
    }
  }
}
