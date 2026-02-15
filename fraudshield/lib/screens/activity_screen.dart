import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../constants/colors.dart';
import '../widgets/glass_surface.dart';
import 'package:intl/intl.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Activity Log',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, size: 20, color: Colors.white),
              onPressed: () {
                // Filter action
              },
            ),
          ),
        ],
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, _) {
          // Combine real alerts with mock data for demonstration
          final activities = _getAllActivities(notificationService.alerts);
          final grouped = _groupActivities(activities);

          return ListView.builder(
            padding: const EdgeInsets.all(20),
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
                        color: Colors.white.withOpacity(0.5),
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

  List<Map<String, dynamic>> _getAllActivities(List<Map<String, dynamic>> realAlerts) {
    // Mock data based on design
    final mockData = [
      {
        'title': 'SMS Phishing Blocked',
        'message': 'A suspicious message containing a fraudulent banking link was automatically intercepted.',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toString(),
        'type': 'danger',
        'icon': Icons.block,
      },
      {
        'title': 'System Scan Completed',
        'message': 'Full device security audit finished. No vulnerabilities or malware found.',
        'timestamp': DateTime.now().subtract(const Duration(hours: 5)).toString(),
        'type': 'success',
        'icon': Icons.check_circle,
      },
      {
        'title': 'Safe Link Verified',
        'message': 'The link "secure-portal.bank.com" was analyzed and confirmed as authentic.',
        'timestamp': DateTime.now().subtract(const Duration(hours: 7)).toString(),
        'type': 'safe',
        'icon': Icons.verified_user,
      },
      {
        'title': 'Identity Guard Active',
        'message': 'Deep web scan completed. Your personal information remains secure.',
        'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 3)).toString(),
        'type': 'info',
        'icon': Icons.fingerprint,
      },
       {
        'title': 'Payment Monitor',
        'message': 'Secure payment channel verified for recent transaction.',
        'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 5)).toString(),
         'type': 'success',
         'icon': Icons.payment,
       },
    ];

    return [...realAlerts, ...mockData];
  }

  Map<String, List<Map<String, dynamic>>> _groupActivities(List<Map<String, dynamic>> activities) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var activity in activities) {
      final date = DateTime.parse(activity['timestamp'].toString());
      final now = DateTime.now();
      String key;

      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        key = 'Today';
      } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
        key = 'Yesterday';
      } else {
        key = DateFormat('MMMM d').format(date);
      }

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(activity);
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
        iconBg = Colors.orange.withOpacity(0.1);
        break;
      case 'success':
        iconColor = AppColors.accentGreen;
        iconBg = AppColors.accentGreen.withOpacity(0.1);
        break;
      case 'safe':
        iconColor = Colors.blue;
        iconBg = Colors.blue.withOpacity(0.1);
        break;
      case 'info':
      default:
        iconColor = Colors.blueAccent;
        iconBg = Colors.blueAccent.withOpacity(0.1);
        break;
    }

    // Override icon if provided in mock data, else default
    final IconData icon = item['icon'] ?? Icons.notifications;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12), // Slightly rounded square like design
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
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item['message'] ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
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

  String _formatTime(String timestamp) {
    final date = DateTime.parse(timestamp);
    return DateFormat('HH:mm').format(date);
  }
}
