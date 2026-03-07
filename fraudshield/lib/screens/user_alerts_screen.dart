import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../design_system/components/app_snackbar.dart';
import 'package:fraudshield/design_system/tokens/design_tokens.dart';

class UserAlertsScreen extends StatelessWidget {
  const UserAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Security Alerts'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.check_circle_outline, color: Colors.white),
            tooltip: 'Mark all as read',
            onPressed: () {
              NotificationService.instance.clearAlerts();
              AppSnackBar.showInfo(context, 'All alerts cleared');
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Consumer<NotificationService>(
        builder: (context, notificationService, _) {
          final alerts = notificationService.alerts;

          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security, size: 80, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'All Systems Safe',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No new threats detected.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(DesignTokens.spacing.lg),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return Container(
                margin: EdgeInsets.only(bottom: DesignTokens.spacing.md),
                padding: EdgeInsets.all(DesignTokens.spacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DesignTokens.radii.md),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: DesignTokens.shadows.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red[100]!),
                      ),
                      child: Icon(Icons.warning_amber_rounded, color: Colors.red),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert['title'] ?? 'Security Alert',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            alert['message'] ?? 'Suspicious activity detected.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _formatDate(alert['timestamp']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    try {
      final date = DateTime.parse(timestamp.toString());
      return '${date.day}/${date.month} ${date.hour}:${date.minute}';
    } catch (_) {
      return 'Just now';
    }
  }
}
