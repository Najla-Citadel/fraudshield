import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'alert_preferences_screen.dart';

class ScamAlertsScreen extends StatefulWidget {
  const ScamAlertsScreen({Key? key}) : super(key: key);

  @override
  State<ScamAlertsScreen> createState() => _ScamAlertsScreenState();
}

class _ScamAlertsScreenState extends State<ScamAlertsScreen> {
  bool _isLoading = true;
  List<dynamic> _trending = [];
  List<dynamic> _nearYou = [];

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    try {
      // Hardcoded KL coordinates for demo (Phase 2 will use real geolocation)
      final data = await ApiService.instance.getTrendingAlerts(
        hours: 72,
        lat: 3.1390,
        lng: 101.6869,
      );
      if (mounted) {
        setState(() {
          _trending = data['trending'] ?? [];
          _nearYou = data['nearYou'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load alerts: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        title: const Text('Threat Intelligence', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlertPreferencesScreen()),
              );
              // Refresh alerts if preferences possibly changed
              if (result == true) {
                _fetchAlerts();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : RefreshIndicator(
              onRefresh: _fetchAlerts,
              color: AppColors.primaryBlue,
              backgroundColor: const Color(0xFF1E293B),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                   // ── Near You Section (if any) ───────────────────────────
                  if (_nearYou.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.primaryBlue, size: 24),
                        const SizedBox(width: 8),
                        Text('Near You', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._nearYou.map((alert) => _buildNearYouCard(alert)),
                    const SizedBox(height: 32),
                  ],

                  // ── Trending Nationwide ────────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.trending_up_rounded, color: Colors.orange, size: 24),
                      const SizedBox(width: 8),
                      Text('Trending Threats', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_trending.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No trending scams detected recently. Stay safe!', style: TextStyle(color: Colors.white54)),
                      ),
                    )
                  else
                    ..._trending.map((alert) => _buildTrendingCard(alert)),
                ],
              ),
            ),
    );
  }

  Widget _buildNearYouCard(dynamic alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(20)),
                child: Text('${alert['reportCount']} Reports', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text('Within ${alert['radius']}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(alert['message'], style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(dynamic alert) {
    final isHigh = alert['severity'] == 'high';
    final severityColor = isHigh ? Colors.red.shade400 : Colors.orange.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  alert['title'] ?? 'Scam Alert',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(isHigh ? Icons.warning_rounded : Icons.info_outline_rounded, color: severityColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      isHigh ? 'HIGH RISK' : 'WATCHLIST',
                      style: TextStyle(color: severityColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert['description'] ?? '',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.report_problem_outlined, color: Colors.white.withOpacity(0.4), size: 16),
                  const SizedBox(width: 6),
                  Text('${alert['reportCount']} incidents past ${alert['timeframe']}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ],
              ),
               if (alert['latestReportAt'] != null)
                 Text(
                   DateFormat('MMM d, h:mm a').format(DateTime.parse(alert['latestReportAt']).toLocal()),
                   style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                 ),
            ],
          ),
        ],
      ),
    );
  }
}
