import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../design_system/tokens/design_tokens.dart';
import '../widgets/glass_surface.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_snackbar.dart';

class RewardsCatalogScreen extends StatefulWidget {
  const RewardsCatalogScreen({super.key});

  @override
  State<RewardsCatalogScreen> createState() => _RewardsCatalogScreenState();
}

class _RewardsCatalogScreenState extends State<RewardsCatalogScreen> {
  final ApiService _api = ApiService.instance;
  bool _loading = true;
  List<Map<String, dynamic>> _rewards = [];
  int _userPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool showLoader = true}) async {
    if (showLoader) setState(() => _loading = true);
    try {
      final [rewardsData, pointsData] = await Future.wait([
        _api.getRewards(),
        _api.getMyPoints(),
      ]);

      if (mounted) {
        setState(() {
          _rewards = List<Map<String, dynamic>>.from(rewardsData['results'] as List);
          _userPoints = (pointsData as Map)['totalPoints'] ?? 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppSnackBar.showError(context, 'Error loading rewards: $e');
      }
    }
  }

  Future<void> _redeemReward(Map<String, dynamic> reward) async {
    final pointsCost = reward['pointsCost'] as int;

    // Check if user has enough points
      AppSnackBar.showWarning(context, 'Insufficient points! You need $pointsCost points.');

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Redeem ${reward['name']}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reward['description']),
            const SizedBox(height: 16),
            Text(
              'Cost: $pointsCost points',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Your balance after: ${_userPoints - pointsCost} points',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          AppButton(
            onPressed: () => Navigator.pop(context, true),
            label: 'Redeem',
            variant: AppButtonVariant.destructive,
            size: AppButtonSize.sm,
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Perform redemption
    try {
      await _api.redeemReward(reward['id']);

        if (mounted) {
          setState(() {
            _userPoints -= pointsCost; // Optimistic update
          });
          
          AppSnackBar.showSuccess(context, 'Successfully redeemed ${reward['name']}!');

          // Background reload to ensure sync with server
          _loadData(showLoader: false);
        }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'REWARDS CATALOG',
      body: _loading
          ? AppLoadingIndicator.center()
          : Column(
              children: [
                // Points Balance Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: GlassSurface(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: Color(0xFFFFD700),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YOUR POINTS',
                              style: TextStyle(
                                fontSize: 11,
                                color: DesignTokens.colors.accentGreen,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              '$_userPoints',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Rewards List
                Expanded(
                  child: _rewards.isEmpty
                      ? Center(
                          child: Text(
                            'No rewards available',
                            style: TextStyle(color: DesignTokens.colors.textGrey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _rewards.length,
                          itemBuilder: (context, index) {
                            final reward = _rewards[index];
                            return _buildRewardCard(reward);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> reward) {
    final name = reward['name'] as String;
    final description = reward['description'] as String;
    final pointsCost = reward['pointsCost'] as int;
    final type = reward['type'] as String;
    final canAfford = _userPoints >= pointsCost;

    // Icon based on type
    IconData icon;
    Color iconColor;
    switch (type) {
      case 'subscription':
        icon = Icons.workspace_premium_rounded;
        iconColor = DesignTokens.colors.premiumYellow;
        break;
      case 'badge':
        icon = Icons.shield_rounded;
        iconColor = DesignTokens.colors.accentGreen;
        break;
      default:
        icon = Icons.card_giftcard_rounded;
        iconColor = DesignTokens.colors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.colors.glassDark.withOpacity(0.4),
        borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
                  border: Border.all(color: iconColor.withOpacity(0.2)),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Points cost and redeem button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: Color(0xFFFFD700),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$pointsCost PTS',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              AppButton(
                label: canAfford ? 'REDEEM' : 'INSUFFICIENT',
                onPressed: canAfford ? () => _redeemReward(reward) : null,
                isLoading: false,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.sm,
                width: 140,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
