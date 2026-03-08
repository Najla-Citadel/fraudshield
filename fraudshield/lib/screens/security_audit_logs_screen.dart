import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../widgets/glass_surface.dart';
import '../services/api_service.dart';
import '../services/scam_scanner_service.dart';
import 'package:intl/intl.dart';

class SecurityAuditLogsScreen extends StatefulWidget {
  const SecurityAuditLogsScreen({super.key});

  @override
  State<SecurityAuditLogsScreen> createState() => _SecurityAuditLogsScreenState();
}

class _SecurityAuditLogsScreenState extends State<SecurityAuditLogsScreen> {
  bool _isLoading = true;
  List<ScamScannerResult> _logs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logs = await ApiService.instance.getSecurityScans();
      if (mounted) {
        setState(() {
          _logs = logs..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load logs: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'SECURITY AUDIT LOGS',
      body: _isLoading
          ? Center(child: AppLoadingIndicator.center())
          : _error != null
              ? _buildErrorState()
              : _logs.isEmpty
                  ? _buildEmptyState()
                  : _buildLogsList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, color: DesignTokens.colors.error, size: 48),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: Colors.white.withOpacity(0.7))),
          const SizedBox(height: 24),
          TextButton(onPressed: _fetchLogs, child: const Text('RETRY')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.clipboardList, color: Colors.white.withOpacity(0.2), size: 64),
          const SizedBox(height: 24),
          Text(
            'No scan history found',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first device audit to see logs here.',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList() {
    return ListView.separated(
      padding: EdgeInsets.all(DesignTokens.spacing.xxl),
      itemCount: _logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final log = _logs[index];
        return _buildLogCard(log);
      },
    );
  }

  Widget _buildLogCard(ScamScannerResult log) {
    final riskyCount = log.riskyApps.length;
    final isSafe = riskyCount == 0;
    
    // Calculate score
    int baseScore = 100;
    for (var app in log.riskyApps) {
      baseScore -= app.score;
    }
    final score = baseScore.clamp(0, 100);
    
    Color scoreColor = score >= 90 ? DesignTokens.colors.success : (score >= 70 ? DesignTokens.colors.warning : DesignTokens.colors.error);
    String status = score >= 90 ? 'SECURE' : (score >= 70 ? 'WARNING' : 'CRITICAL');

    return GlassSurface(
      borderRadius: 20,
      onTap: () => Navigator.pushNamed(context, '/device-scan', arguments: log),
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacing.xl),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scoreColor.withOpacity(0.3), width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '$score',
                style: TextStyle(color: scoreColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(status, style: TextStyle(color: scoreColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(
                        DateFormat('MMM dd, HH:mm').format(log.timestamp),
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSafe ? 'No threats found' : '$riskyCount potential threats detected',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${log.totalAppsScanned} apps audited',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight, color: Colors.white.withOpacity(0.2), size: 18),
          ],
        ),
      ),
    );
  }
}
