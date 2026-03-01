import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';

class ScamAlertsScreen extends StatefulWidget {
  const ScamAlertsScreen({Key? key}) : super(key: key);

  @override
  State<ScamAlertsScreen> createState() => _ScamAlertsScreenState();
}

class _ScamAlertsScreenState extends State<ScamAlertsScreen> {
  List<dynamic> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    try {
      final alerts = await ApiService.instance.getUserAlerts();
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load alerts: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await ApiService.instance.markAlertsAsRead();
      _fetchAlerts(); // Refresh
    } catch (e) {
      debugPrint('Error marking alerts as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Security Alerts',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Mark All as Read',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : _alerts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchAlerts,
                  color: AppColors.primaryBlue,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _alerts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final alert = _alerts[index];
                      final category = alert['category'] ?? 'COMMUNITY';
                      final severity = alert['severity'] ?? 'LOW';

                      if (category == 'PHISHING' && (severity == 'HIGH' || severity == 'CRITICAL')) {
                        return _buildHighRiskAlertCard(alert);
                      }

                      return _buildStandardAlertCard(alert);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.shieldCheck, size: 64, color: AppColors.greyText.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'All Clear!',
            style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'No active security alerts for your account.',
            style: TextStyle(color: AppColors.greyText, fontSize: 14),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: _seedDemoAlerts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Fetch Demo Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _seedDemoAlerts() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.instance.get('/alerts/seed');
      await _fetchAlerts(); 
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to seed alerts: $e')),
        );
      }
    }
  }

  Widget _buildHighRiskAlertCard(dynamic alert) {
    final metadata = alert['metadata'] as Map<String, dynamic>? ?? {};
    final createdAt = DateTime.parse(alert['createdAt']).toLocal();
    final timeStr = DateFormat('h:mm a').format(createdAt);
    final dateStr = DateFormat('MMM d, yyyy').format(createdAt);
    final isToday = DateUtils.isSameDay(createdAt, DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0), // Light red bg
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E), // Rose red
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(LucideIcons.alertTriangle, color: Colors.white, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'HIGH RISK',
                  style: TextStyle(
                    color: Color(0xFFF43F5E),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            alert['title'] ?? 'Suspicious activity detected',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${isToday ? 'Today' : dateStr} at $timeStr',
            style: const TextStyle(
              color: AppColors.greyText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(text: '"${alert['message']}"'),
                    ],
                  ),
                ),
                if (metadata.containsKey('sender')) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble, color: AppColors.greyText, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'Sender: ${metadata['sender']}',
                        style: TextStyle(
                          color: AppColors.greyText.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => _resolveAlert(alert['id'], 'BLOCK'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48), // Deep Rose
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Block & Report Sender', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => _resolveAlert(alert['id'], 'DISMISS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9), // Slate 100
                foregroundColor: AppColors.textDark,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Not a Scam', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardAlertCard(dynamic alert) {
    final category = alert['category'] ?? 'COMMUNITY';
    final severity = alert['severity'] ?? 'LOW';
    final createdAt = DateTime.parse(alert['createdAt']).toLocal();
    final dateStr = DateFormat('MMM d, yyyy').format(createdAt);
    final timeStr = DateFormat('h:mm a').format(createdAt);
    final isToday = DateUtils.isSameDay(createdAt, DateTime.now());

    Color iconColor;
    Color bgColor;
    IconData icon;
    
    switch (category) {
      case 'LOGIN':
        iconColor = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        icon = Icons.person_outline;
        break;
      case 'SYSTEM_SCAN':
        iconColor = const Color(0xFF2563EB);
        bgColor = const Color(0xFFDBEAFE);
        icon = Icons.shield_outlined;
        break;
      case 'NETWORK':
        iconColor = const Color(0xFF9CA3AF);
        bgColor = const Color(0xFFF3F4F6);
        icon = LucideIcons.link2Off;
        break;
      default:
        iconColor = AppColors.primaryBlue;
        bgColor = AppColors.primaryBlue.withValues(alpha: 0.1);
        icon = Icons.notifications_none;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title'] ?? 'Security Update',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isToday ? 'Today' : dateStr} at $timeStr',
                  style: const TextStyle(
                    color: AppColors.greyText,
                    fontSize: 12,
                  ),
                ),
                if (alert['message'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    alert['message'],
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, color: AppColors.greyText, size: 16),
        ],
      ),
    );
  }

  Future<void> _resolveAlert(String alertId, String action) async {
    try {
      await ApiService.instance.resolveAlert(alertId, action);
      _fetchAlerts(); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alert ${action == 'BLOCK' ? 'blocked' : 'dismissed'}')),
        );
      }
    } catch (e) {
      debugPrint('Error resolving alert: $e');
    }
  }
}
