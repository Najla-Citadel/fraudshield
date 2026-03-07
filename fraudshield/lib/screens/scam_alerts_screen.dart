import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../services/api_service.dart';
import '../widgets/glass_surface.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../design_system/components/app_empty_state.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_snackbar.dart';

class ScamAlertsScreen extends StatefulWidget {
  const ScamAlertsScreen({super.key});

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
        AppSnackBar.showError(context, 'Failed to load alerts: $e');
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
    return ScreenScaffold(
      title: 'Notifications',
      actions: [
        TextButton(
          onPressed: _markAllAsRead,
          child: Text(
            'Mark all as read',
            style: TextStyle(
              color: DesignTokens.colors.accentGreen,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        SizedBox(width: 20),
      ],
      body: _isLoading
          ? AppLoadingIndicator.center(
              color: DesignTokens.colors.primary)
          : _alerts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchAlerts,
                  color: DesignTokens.colors.primary,
                  backgroundColor: DesignTokens.colors.surfaceDark,
                  child: ListView(
                    padding:
                        EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xxl, vertical: DesignTokens.spacing.sm),
                    children: _buildGroupedAlertList(),
                  ),
                ),
    );
  }

  List<Widget> _buildGroupedAlertList() {
    final List<Widget> items = [];

    // Simple grouping logic
    final today = _alerts.where((a) => _isToday(a['createdAt'])).toList();
    final yesterday =
        _alerts.where((a) => _isYesterday(a['createdAt'])).toList();
    final older = _alerts
        .where(
            (a) => !_isToday(a['createdAt']) && !_isYesterday(a['createdAt']))
        .toList();

    if (today.isNotEmpty) {
      items.add(_buildSectionHeader('TODAY'));
      items.addAll(today.map((a) => _buildAlertItem(a)));
    }

    if (yesterday.isNotEmpty) {
      items.add(_buildSectionHeader('YESTERDAY'));
      items.addAll(yesterday.map((a) => _buildAlertItem(a)));
    }

    if (older.isNotEmpty) {
      items.add(_buildSectionHeader('EARLIER'));
      items.addAll(older.map((a) => _buildAlertItem(a)));
    }

    items.add(SizedBox(height: 100)); // Bottom padding for nav bar

    return items;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(top: DesignTokens.spacing.xxl, bottom: DesignTokens.spacing.lg),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  bool _isToday(String dateStr) {
    final date = DateTime.parse(dateStr).toLocal();
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(String dateStr) {
    final date = DateTime.parse(dateStr).toLocal();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  Widget _buildAlertItem(dynamic alert) {
    final category = alert['category'] ?? 'COMMUNITY';
    final severity = alert['severity'] ?? 'LOW';

    if (category == 'LOGIN' && severity == 'HIGH') {
      return _buildLoginAlertCard(alert);
    }

    if ((category == 'PHISHING' ||
            category == 'MULE_ACCOUNT' ||
            category == 'MACAU_SCAM') &&
        (severity == 'HIGH' || severity == 'CRITICAL')) {
      return _buildHighRiskAlertCard(alert);
    }

    return _buildStandardAlertCard(alert);
  }

  Widget _buildLoginAlertCard(dynamic alert) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacing.lg),
      child: GlassSurface(
        padding: EdgeInsets.all(DesignTokens.spacing.xl),
        borderRadius: 24,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(DesignTokens.spacing.md),
              decoration: BoxDecoration(
                color: Color(0xFFFFE4E6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radii.md),
              ),
              child: Icon(LucideIcons.alertTriangle,
                  color: Color(0xFFE11D48), size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          alert['title'] ?? 'Security Alert',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        _getTimeAgo(alert['createdAt']),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    alert['message'] ?? '',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.5),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      _buildActionButton('It wasn\'t me',
                          isPrimary: true,
                          onTap: () => _resolveAlert(alert['id'], 'BLOCK')),
                      SizedBox(width: 12),
                      _buildActionButton('Details',
                          isPrimary: false, onTap: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label,
      {required bool isPrimary, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.lg, vertical: DesignTokens.spacing.sm),
        decoration: BoxDecoration(
          color: isPrimary
              ? Color(0xFFDC2626)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(String dateStr) {
    final date = DateTime.parse(dateStr).toLocal();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildEmptyState() {
    return const AppEmptyState(
      icon: LucideIcons.shieldCheck,
      title: 'All Clear!',
      description: 'No active security alerts for your account.',
    );
  }

  Widget _buildHighRiskAlertCard(dynamic alert) {
    final metadata = alert['metadata'] as Map<String, dynamic>? ?? {};
    final createdAt = DateTime.parse(alert['createdAt']).toLocal();
    final timeStr = DateFormat('h:mm a').format(createdAt);
    final dateStr = DateFormat('MMM d, yyyy').format(createdAt);
    final isToday = DateUtils.isSameDay(createdAt, DateTime.now());
    final bool isRead = alert['isRead'] ?? false;

    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacing.lg),
      child: InkWell(
        onTap: () {
          if (!isRead) {
            setState(() {
              alert['isRead'] = true;
            });
          }
        },
        borderRadius: BorderRadius.circular(DesignTokens.radii.xl),
        child: GlassSurface(
          padding: EdgeInsets.all(DesignTokens.spacing.xxl),
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(DesignTokens.spacing.md),
                        decoration: BoxDecoration(
                          color: Color(0xFFF43F5E), // Rose red
                          borderRadius: BorderRadius.circular(DesignTokens.radii.md),
                        ),
                        child: Icon(LucideIcons.alertTriangle,
                            color: Colors.white, size: 24),
                      ),
                      if (!isRead) ...[
                        SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(0xFFF43F5E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: DesignTokens.spacing.md, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFF43F5E).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
                    ),
                    child: Text(
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
              SizedBox(height: 20),
              Text(
                alert['title'] ?? 'Suspicious activity detected',
                style: TextStyle(
                  color: Colors.white.withOpacity(isRead ? 0.7 : 1.0),
                  fontSize: 18,
                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '${isToday ? 'Today' : dateStr} at $timeStr',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(DesignTokens.spacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(DesignTokens.radii.md),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
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
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.chat_bubble,
                              color: Colors.white24, size: 14),
                          SizedBox(width: 8),
                          Text(
                            'Sender: ${metadata['sender']}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 24),
              AppButton(
                onPressed: () => _resolveAlert(alert['id'], 'BLOCK'),
                label: 'Block & Report Sender',
                variant: AppButtonVariant.destructive,
                size: AppButtonSize.lg,
              ),
              SizedBox(height: 12),
              AppButton(
                onPressed: () => _resolveAlert(alert['id'], 'DISMISS'),
                label: 'Not a Scam',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.lg,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandardAlertCard(dynamic alert) {
    final category = alert['category'] ?? 'COMMUNITY';
    final bool isRead = alert['isRead'] ?? false;

    Color iconColor;
    Color bgColor;
    IconData icon;

    switch (category) {
      case 'LOGIN':
        iconColor = Color(0xFFF59E0B);
        bgColor = Color(0xFFFEF3C7);
        icon = LucideIcons.user;
        break;
      case 'SYSTEM_SCAN':
        iconColor = Color(0xFF10B981);
        bgColor = Color(0xFFD1FAE5);
        icon = LucideIcons.shieldCheck;
        if (alert['title']?.toString().contains('Report') ?? false) {
          iconColor = Color(0xFF3B82F6);
          bgColor = Color(0xFFDBEAFE);
          icon = LucideIcons.shield;
        }
        break;
      case 'NETWORK':
        iconColor = Color(0xFF9CA3AF);
        bgColor = Color(0xFFF3F4F6);
        icon = LucideIcons.link2Off;
        break;
      case 'COMMUNITY':
        if (alert['title']?.toString().contains('Scam Trend') ?? false) {
          iconColor = Color(0xFFF59E0B);
          bgColor = Color(0xFFFEF3C7);
          icon = LucideIcons.lightbulb;
        } else if (alert['title']?.toString().contains('Benefit') ?? false) {
          iconColor = Color(0xFF8B5CF6);
          bgColor = Color(0xFFF5F3FF);
          icon = LucideIcons.award;
        } else {
          iconColor = DesignTokens.colors.primary;
          bgColor = DesignTokens.colors.primary.withOpacity(0.1);
          icon = LucideIcons.users;
        }
        break;
      default:
        iconColor = DesignTokens.colors.primary;
        bgColor = DesignTokens.colors.primary.withOpacity(0.1);
        icon = LucideIcons.bell;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacing.lg),
      child: InkWell(
        onTap: () {
          if (!isRead) {
            setState(() {
              alert['isRead'] = true;
            });
          }
        },
        borderRadius: BorderRadius.circular(DesignTokens.radii.xl),
        child: GlassSurface(
          padding: EdgeInsets.all(DesignTokens.spacing.xl),
          borderRadius: 24,
          child: Opacity(
            opacity: isRead ? 0.6 : 1.0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(DesignTokens.spacing.md),
                  decoration: BoxDecoration(
                    color: bgColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radii.md),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    alert['title'] ?? 'Security Update',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: isRead
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (!isRead) ...[
                                  SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: iconColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            _getTimeAgo(alert['createdAt']),
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        alert['message'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resolveAlert(String alertId, String action) async {
    try {
      await ApiService.instance.resolveAlert(alertId, action);
      _fetchAlerts(); // Refresh
      if (mounted) {
        AppSnackBar.showInfo(context, 'Alert ${action == 'BLOCK' ? 'blocked' : 'dismissed'}');
      }
    } catch (e) {
      debugPrint('Error resolving alert: $e');
    }
  }
}
