import 'dart:developer';
import 'package:flutter/material.dart';
 import '../design_system/components/app_loading_indicator.dart';
import '../design_system/components/app_empty_state.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../services/api_service.dart';

class PointsHistoryScreen extends StatefulWidget {
  const PointsHistoryScreen({super.key});

  @override
  State<PointsHistoryScreen> createState() => _PointsHistoryScreenState();
}

class _PointsHistoryScreenState extends State<PointsHistoryScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.instance.getMyPoints();
      if (!mounted) return;
      setState(() {
        _history = List<Map<String, dynamic>>.from(res['transactions'] ?? []);
        _loading = false;
      });
    } catch (e) {
      log('Error loading history: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Points History',
      body: _loading
          ? AppLoadingIndicator.center()
          : _history.isEmpty
              ? const AppEmptyState(
                  icon: LucideIcons.history,
                  title: 'No history yet',
                  description: 'Your points transactions will appear here.',
                )
              : ListView.builder(
                  padding: EdgeInsets.all(DesignTokens.spacing.lg),
                  itemCount: _history.length,
                  itemBuilder: (_, i) {
                    final item = _history[i];
                    final amount = item['amount'] as int;
                    final positive = amount >= 0;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: positive
                              ? Colors.green[100]
                              : Colors.red[100],
                          child: Icon(
                            positive ? Icons.add : Icons.remove,
                            color: positive
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        title: Text(item['description'] ?? ''),
                        subtitle:
                            Text(item['createdAt'].toString()),
                        trailing: Text(
                          '${positive ? '+' : ''}$amount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: positive
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
