import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../design_system/components/app_snackbar.dart';
import 'package:fraudshield/design_system/tokens/design_tokens.dart';
import 'package:fraudshield/design_system/layouts/screen_scaffold.dart';
import 'package:lucide_icons/lucide_icons.dart';

class UserAlertsScreen extends StatelessWidget {
  const UserAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Security Alerts',
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.checkCircle, color: Colors.white),
          tooltip: 'Mark all as read',
          onPressed: () {
            NotificationService.instance.clearAlerts();
            AppSnackBar.showInfo(context, 'All alerts cleared');
          },
        ),
      ],
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
                      color: DesignTokens.colors.textLight,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No new threats detected.',
                    style: TextStyle(
                      fontSize: 16,
                      color: DesignTokens.colors.textLight.withOpacity(0.6),
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
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(DesignTokens.radii.md),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: DesignTokens.shadows.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: const Icon(LucideIcons.alertTriangle, color: Colors.red),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert['title'] ?? 'Security Alert',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert['message'] ?? 'Suspicious activity detected.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(alert['timestamp']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.4),
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
