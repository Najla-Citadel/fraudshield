// lib/screens/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/core/primary_button.dart';
import '../widgets/core/status_badge.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = false;
  Map<String, dynamic>? _activeSub;
  List<Map<String, dynamic>> _plans = [];

  bool get hasActiveSub => _activeSub != null && _activeSub!['status'] == 'active';

  @override
  void initState() {
    super.initState();
    _loadPlans();
    _loadActiveSubscription();
  }

  Future<void> _loadPlans() async {
    final res = await _supabase.from('subscription_plans').select().order('price', ascending: true);
    if (!mounted) return;
    setState(() => _plans = List<Map<String, dynamic>>.from(res));
  }

  Future<void> _loadActiveSubscription() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final res = await _supabase
        .from('user_subscriptions')
        .select('*, subscription_plans(name)')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (!mounted) return;
    setState(() => _activeSub = res);
  }

  Future<void> _subscribe(Map<String, dynamic> plan) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      await _supabase.from('user_subscriptions').insert({
        'user_id': user.id,
        'plan_id': plan['id'],
        'status': 'active',
        'started_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription activated')),
      );

      await _loadActiveSubscription();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelSubscription() async {
    if (_activeSub == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text('You will keep access until expiry.\n\nProceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _supabase.from('user_subscriptions').update({
      'status': 'cancelled',
      'cancelled_at': DateTime.now().toIso8601String(),
    }).eq('id', _activeSub!['id']);

    await _loadActiveSubscription();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Subscription')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.l),
            
            // 🔹 HERO TEXT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Column(
                children: [
                  Text('Upgrade Your Security', style: AppTypography.h1),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Unlock advanced AI protection and real-time monitoring.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyM.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.l),

            // 🔹 ACTIVE SUB
            if (hasActiveSub) _ActivePlanCard(activeSub: _activeSub!, onCancel: _cancelSubscription),

            // 🔹 PLANS LIST
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: AppSpacing.screenPadding,
              itemCount: _plans.length,
              itemBuilder: (_, index) {
                final plan = _plans[index];
                return _PlanCard(
                  plan: plan,
                  loading: _loading,
                  isActive: _activeSub?['plan_id'] == plan['id'],
                  onPressed: () => _subscribe(plan),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _ActivePlanCard extends StatelessWidget {
  final Map<String, dynamic> activeSub;
  final VoidCallback onCancel;

  const _ActivePlanCard({required this.activeSub, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusM),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: AppColors.success, size: 32),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Plan', style: AppTypography.bodyS),
                Text(
                  activeSub['subscription_plans']['name'],
                  style: AppTypography.h3.copyWith(color: AppColors.success),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool loading;
  final bool isActive;
  final VoidCallback onPressed;

  const _PlanCard({
    required this.plan,
    required this.loading,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRecommended = plan['price'] > 0; // Simple logic for demo
    final Color color = isRecommended ? AppColors.primary : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.l),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        border: isRecommended ? Border.all(color: AppColors.primary, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRecommended)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'RECOMMENDED',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(plan['name'], style: AppTypography.h2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                    Text('RM ${plan['price']}', style: AppTypography.h2.copyWith(color: AppColors.primary)),
                    Text('/month', style: AppTypography.bodyS),
                 ],
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.m),
          const Divider(),
          const SizedBox(height: AppSpacing.m),

          ...(plan['features'] as List).map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 18, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(child: Text(f, style: AppTypography.bodyM)),
              ],
            ),
          )),

          const SizedBox(height: AppSpacing.l),

          PrimaryButton(
            label: isActive ? 'Current Plan' : (loading ? 'Processing...' : 'Activate Plan'),
            onPressed: isActive || loading ? null : onPressed,
            isFullWidth: true,
            // Use grey style if active
          ),
        ],
      ),
    );
  }
}
