import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../services/api_service.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../widgets/glass_surface.dart';
import '../design_system/components/app_snackbar.dart';
import '../design_system/components/app_button.dart';

class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({super.key});

  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen> {
  final ApiService _api = ApiService.instance;

  List<Map<String, dynamic>> _alerts = [];
  bool _loading = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchAlerts();
    });
  }

  Future<void> _fetchAlerts() async {
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      final data = await _api.getAdminAlerts();
      setState(() {
        _alerts = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (mounted) {
        log('Failed to load alerts: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _labelTx(String txId, String alertId, String label) async {
    try {
      await _api.labelTransaction(
        txId: txId,
        alertId: alertId,
        label: label,
      );

      // Update UI
      setState(() {
        final idx = _alerts.indexWhere((a) => a['id'] == alertId);
        if (idx != -1) _alerts[idx]['processed'] = true;
      });

      if (!mounted) return;
      AppSnackBar.showSuccess(context, 'Marked as $label');
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed: $e');
      }
    }
  }

  Future<void> _viewTransaction(String txId) async {
    try {
      final tx = await _api.getTransactionDetails(txId);

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('Transaction ${tx['id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Amount: ${tx['amount']}'),
              Text('Merchant: ${tx['merchant']}'),
              Text('Decision: ${tx['decision']}'),
              Text('Risk Score: ${tx['riskScore']}'),
              const SizedBox(height: 12),
              AppButton(
                onPressed: () => Navigator.pop(context),
                label: 'Close',
                variant: AppButtonVariant.primary,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error: $e');
      }
    }
  }

  Widget _alertCard(Map<String, dynamic> a) {
    final String txId = a['txId'] ?? '';
    final String alertId = a['id'] ?? '';
    final bool processed = a['processed'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassSurface(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TX: $txId',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Decision: ${a['decision']}',
              style: TextStyle(color: Colors.white.withOpacity(0.7))),
          Text('Risk Score: ${a['riskScore']}',
              style: TextStyle(color: Colors.white.withOpacity(0.7))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: AppButton(
                onPressed: () => _viewTransaction(txId),
                label: 'View',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                onPressed: processed ? null : () => _labelTx(txId, alertId, 'fraud'),
                label: 'Fraud',
                variant: AppButtonVariant.destructive,
                size: AppButtonSize.sm,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                onPressed: processed ? null : () => _labelTx(txId, alertId, 'legit'),
                label: 'Legit',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.sm,
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'ADMIN ALERTS',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _fetchAlerts,
        )
      ],
      body: _loading
          ? AppLoadingIndicator.center()
          : _alerts.isEmpty
              ? const Center(child: Text('No alerts yet', style: TextStyle(color: Colors.white)))
              : RefreshIndicator(
                  onRefresh: _fetchAlerts,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _alerts.map(_alertCard).toList(),
                  ),
                ),
    );
  }
}
