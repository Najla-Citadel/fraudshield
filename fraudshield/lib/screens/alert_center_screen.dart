import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/notification_service.dart';
import '../constants/colors.dart';
import '../widgets/glass_surface.dart';
import '../widgets/fade_in_slide_up.dart';

class AlertCenterScreen extends StatelessWidget {
  const AlertCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Alert Center',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: AppColors.textDark, size: 20),
            onPressed: () {
              NotificationService.instance.clearAlerts();
            },
          ),
        ],
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          final alerts = notificationService.alerts;

          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.bellOff, size: 64, color: AppColors.textDark.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'No new alerts',
                    style: TextStyle(
                      color: AppColors.textDark.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return FadeInSlideUp(
                delay: Duration(milliseconds: index * 50),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _AlertCard(alert: alert),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final severity = alert['severity'] ?? 'info';
    final color = _getSeverityColor(severity);
    final icon = _getSeverityIcon(severity);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                color: color,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  alert['title'] ?? 'Security Alert',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                if (alert['timestamp'] != null)
                                  Text(
                                    _formatTimestamp(alert['timestamp']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textDark.withValues(alpha: 0.4),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert['message'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textDark.withValues(alpha: 0.7),
                                height: 1.4,
                              ),
                            ),
                            if (alert['type'] != null) ...[
                              const SizedBox(height: 12),
                              _buildActionButton(context, alert),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, Map<String, dynamic> alert) {
    return InkWell(
      onTap: () {
        // Handle action based on type
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View Details',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Icon(LucideIcons.chevronRight, size: 14, color: AppColors.primaryBlue),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
        return Colors.redAccent;
      case 'suspicious':
      case 'medium':
        return Colors.orangeAccent;
      default:
        return AppColors.primaryBlue;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
        return LucideIcons.shieldAlert;
      case 'suspicious':
      case 'medium':
        return LucideIcons.alertTriangle;
      default:
        return LucideIcons.info;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    // Simple mock formatting
    return 'Just now';
  }
}
