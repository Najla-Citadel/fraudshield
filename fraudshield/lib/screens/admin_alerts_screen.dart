import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Marked as $label')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
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
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _alertCard(Map<String, dynamic> a) {
    final String txId = a['txId'] ?? '';
    final String alertId = a['id'] ?? '';
    final bool processed = a['processed'] == true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TX: $txId', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Decision: ${a['decision']}'),
          Text('Risk Score: ${a['riskScore']}'),
          const SizedBox(height: 8),

          Row(children: [
            ElevatedButton(
              onPressed: () => _viewTransaction(txId),
              child: const Text('View'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: processed ? null : () => _labelTx(txId, alertId, 'fraud'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Fraud'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: processed ? null : () => _labelTx(txId, alertId, 'legit'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Legit'),
            ),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAlerts,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? const Center(child: Text('No alerts yet'))
              : RefreshIndicator(
                  onRefresh: _fetchAlerts,
                  child: ListView(
                    children: _alerts.map(_alertCard).toList(),
                  ),
                ),
    );
  }
}
