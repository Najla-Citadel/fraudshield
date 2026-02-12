import 'dart:developer';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_surface.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final ApiService _api = ApiService.instance;

  bool _loading = false;
  Map<String, dynamic>? _activeSub;
  List<Map<String, dynamic>> _plans = [];

  bool get hasActiveSub =>
      _activeSub != null && _activeSub!['status'] == 'ACTIVE';

  @override
  void initState() {
    super.initState();
    _loadPlans();
    _loadActiveSubscription();
  }

  // =========================
  // LOAD PLANS
  // =========================
  Future<void> _loadPlans() async {
    try {
      final res = await _api.getPlans();
      if (!mounted) return;
      setState(() => _plans = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      log('Error loading plans: $e');
    }
  }

  // =========================
  // LOAD ACTIVE SUB
  // =========================
  Future<void> _loadActiveSubscription() async {
    try {
      final res = await _api.getMySubscription();
      if (!mounted) return;
      setState(() => _activeSub = res);
    } catch (e) {
      log('No active subscription or error: $e');
      if (mounted) setState(() => _activeSub = null);
    }
  }

  // =========================
  // SUBSCRIBE
  // =========================
  Future<void> _subscribe(Map<String, dynamic> plan) async {
    setState(() => _loading = true);

    try {
      await _api.createSubscription(
        planId: plan['id'],
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription activated')),
      );

      await _loadActiveSubscription();
    } catch (e) {
      log('Error subscribing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to activate: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // =========================
  // CANCEL
  // =========================
  Future<void> _cancelSubscription() async {
    if (_activeSub == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text('You will keep access until expiry.\n\nProceed?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // In this MVP, we might just mark it as cancelled or leave it. 
    // Backend needs a cancel endpoint. For now, we'll just show a message.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cancellation requested.')),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 16),

          // 🔹 ACTIVE SUB HEADER
          if (hasActiveSub) _activeHeader(),

          // 🔹 HERO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const Text(
                  'Upgrade Security',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a protection tier to unlock advanced AI defenses.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // 🔹 PLANS
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _plans.length,
              itemBuilder: (_, index) {
                final plan = _plans[index];

                return _ModernPlanCard(
                  plan: plan,
                  loading: _loading,
                  disabled:
                      hasActiveSub && _activeSub?['planId'] != plan['id'],
                  isCurrent: _activeSub?['planId'] == plan['id'],
                  onPressed: () => _subscribe(plan),
                );
              },
            ),
          ),

          // 🔹 CANCEL
          if (hasActiveSub)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: _cancelSubscription,
                child: const Text(
                  'Cancel Subscription',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================
  // ACTIVE HEADER
  // =========================
  Widget _activeHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Active Plan',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _activeSub!['plan']?['name'] ?? 'Premium Tier',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////////
/// MODERN PLAN CARD
////////////////////////////////////////////////////////////////

class _ModernPlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final VoidCallback onPressed;
  final bool isCurrent;
  final bool disabled;
  final bool loading;

  const _ModernPlanCard({
    required this.plan,
    required this.onPressed,
    required this.isCurrent,
    required this.disabled,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = plan['price'] == 0
        ? Colors.green
        : plan['price'] == 5.90
            ? theme.colorScheme.primary
            : Colors.orange;

    final isRecommended = plan['price'] == 5.90;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: disabled ? 0.5 : 1,
        child: GlassSurface(
          padding: const EdgeInsets.all(24),
          borderRadius: 28,
          // Highlight recommended plan
          accentColor: isRecommended ? color : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isRecommended)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'RECOMMENDED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              Text(
                plan['name'],
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM ${plan['price']}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('/month', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 16),
              ...(plan['features'] as List)
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: color, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(f, style: theme.textTheme.bodyMedium)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AdaptiveButton(
                  onPressed:
                      (loading || disabled || isCurrent) ? null : onPressed,
                  text: isCurrent
                        ? 'Current Plan'
                        : loading
                            ? 'Processing...'
                            : 'Activate Tier',
                  isLoading: loading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
