import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'points_details_screen.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_snackbar.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => PointsScreenState();
}

class PointsScreenState extends State<PointsScreen> {
  final ApiService _api = ApiService.instance;
  bool _loading = true;
  bool _hasError = false;
  String _userTier = 'BRONZE';
  double _userDiscount = 0.0;
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> _rewards = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> refreshData() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    await _loadPoints();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    await _loadPoints();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadPoints() async {
    try {
      final rewardsRes = await _api.getRewards();
      if (mounted) {
        setState(() {
          _rewards =
              List<Map<String, dynamic>>.from(rewardsRes['results'] as List);
          _userTier = rewardsRes['userTier'] ?? 'BRONZE';
          _userDiscount = (rewardsRes['userDiscount'] ?? 0).toDouble();
        });
      }
      await context.read<AuthProvider>().refreshProfile();
    } catch (e) {
      log('Error loading points/rewards: $e');
      if (e.toString().contains('403')) {
        if (mounted) {
          setState(() => _hasError = false);
        }
      } else if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  Future<void> _redeemReward(Map<String, dynamic> reward) async {
    final points = context.read<AuthProvider>().user?.profile?.points ?? 0;
    final pointsCost = reward['pointsCost'] as int;
    if (points < pointsCost) {
      AppSnackBar.showError(context, 'Insufficient points!');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.colors.backgroundDark,
        title: Text('Redeem ${reward['name']}?',
            style: const TextStyle(color: Colors.white)),
        content: Text(
          'Cost: $pointsCost points\nYour balance after: ${points - pointsCost} points',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white))),
          AppButton(
            onPressed: () => Navigator.pop(context, true),
            label: 'Redeem',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.sm,
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.redeemReward(reward['id']);
      if (mounted) {
        AppSnackBar.showSuccess(context, '✅ Redeemed ${reward['name']}!');
        await context.read<AuthProvider>().refreshProfile();
        refreshData();
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
      title: 'Rewards',
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: IconButton(
            icon:
                const Icon(LucideIcons.history, size: 20, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PointsDetailsScreen()),
              );
            },
            tooltip: 'Points History',
          ),
        ),
      ],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, size: 48, color: Colors.white24),
            const SizedBox(height: 16),
            const Text('Failed to load rewards',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            AppButton(
              onPressed: refreshData,
              label: 'Retry',
              variant: AppButtonVariant.outline,
            ),
          ],
        ),
      );
    }

    if (_loading) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: const [
            SizedBox(height: 20),
            // Mock skeletons
            _Skeleton(height: 180),
            SizedBox(height: 24),
            _Skeleton(height: 60),
            SizedBox(height: 24),
            _Skeleton(height: 250),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 16),
              _buildCategorySelector(),
              const SizedBox(height: 16),
              if (_selectedCategory == 'All' ||
                  _selectedCategory == 'Security') ...[
                _buildSectionHeader('Security Upgrades'),
                const SizedBox(height: 12),
                ..._rewards
                    .where((r) =>
                        r['type'].toString().toUpperCase() == 'SUBSCRIPTION')
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildFeaturedReward(r),
                        )),
                if (_rewards
                    .where((r) =>
                        r['type'].toString().toUpperCase() == 'SUBSCRIPTION')
                    .isEmpty)
                  _buildEmptyState(LucideIcons.shieldAlert,
                      'No security upgrades available'),
                const SizedBox(height: 32),
              ],
              if (_selectedCategory == 'All' ||
                  _selectedCategory == 'Vouchers') ...[
                _buildSectionHeader('Store Items & Vouchers'),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 260,
                  ),
                  itemCount: _rewards
                      .where((r) =>
                          r['type'].toString().toUpperCase() != 'SUBSCRIPTION')
                      .length,
                  itemBuilder: (context, index) {
                    final r = _rewards
                        .where((r) =>
                            r['type'].toString().toUpperCase() !=
                            'SUBSCRIPTION')
                        .toList()[index];
                    return _buildRewardCard(r, false);
                  },
                ),
                if (_rewards
                    .where((r) =>
                        r['type'].toString().toUpperCase() != 'SUBSCRIPTION')
                    .isEmpty)
                  _buildEmptyState(
                      LucideIcons.packageOpen, 'No store items available'),
                const SizedBox(height: 32),
              ],
              _buildDonationCard(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final userPoints = context.watch<AuthProvider>().user?.profile?.points ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PointsDetailsScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DesignTokens.colors.glassDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'AVAILABLE BALANCE',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: DesignTokens.colors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$userPoints',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  TextSpan(
                    text: ' PTS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DesignTokens.colors.accentGreen
                          .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (_userDiscount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignTokens.colors.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: DesignTokens.colors.accentGreen
                          .withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.tag,
                        size: 14, color: DesignTokens.colors.accentGreen),
                    const SizedBox(width: 6),
                    Text(
                      '${(_userDiscount * 100).toInt()}% $_userTier Discount Active',
                      style: TextStyle(
                        color: DesignTokens.colors.accentGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'You\'ve reached ${_calculateTierName(context.read<AuthProvider>().user?.profile?.totalPoints ?? 0)} status. Keep it up!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _categoryChip('All', LucideIcons.layers,
              isActive: _selectedCategory == 'All'),
          const SizedBox(width: 12),
          _categoryChip('Vouchers', LucideIcons.ticket,
              isActive: _selectedCategory == 'Vouchers'),
          const SizedBox(width: 12),
          _categoryChip('Security', LucideIcons.shieldCheck,
              isActive: _selectedCategory == 'Security'),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, IconData icon, {bool isActive = false}) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive
              ? DesignTokens.colors.accentGreen
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22),
          border: isActive
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.black87 : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black87 : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'View All',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: DesignTokens.colors.accentGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedReward(Map<String, dynamic> reward) {
    return _buildRewardCard(reward, true);
  }

  Widget _buildRewardCard(Map<String, dynamic> reward, bool isFeatured) {
    final balance = context.watch<AuthProvider>().user?.profile?.points ?? 0;
    final name = reward['name'] ?? 'Item';
    final desc = reward['description'] ?? '';
    final cost = reward['pointsCost'] ?? 0;
    final canAfford = balance >= cost;
    final isLocked = reward['isLocked'] ?? false;
    final requiredTier = reward['requiredTier'] ?? 'SILVER';

    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.colors.glassDark,
        borderRadius: BorderRadius.circular(isFeatured ? 24 : 20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: isFeatured ? 140 : 100,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isFeatured
                    ? [
                        Colors.blue.withValues(alpha: 0.2),
                        Colors.blue.withValues(alpha: 0.05)
                      ]
                    : [
                        DesignTokens.colors.accentGreen.withValues(alpha: 0.1),
                        DesignTokens.colors.accentGreen.withValues(alpha: 0.02)
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isFeatured ? 24 : 20)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    isLocked
                        ? LucideIcons.lock
                        : (isFeatured ? LucideIcons.shield : LucideIcons.gift),
                    size: isFeatured ? 64 : 40,
                    color: isLocked
                        ? Colors.white24
                        : (isFeatured
                            ? Colors.blue.withValues(alpha: 0.5)
                            : DesignTokens.colors.accentGreen
                                .withValues(alpha: 0.5)),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLocked
                          ? Colors.black54
                          : DesignTokens.colors.accentGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$cost PTS',
                      style: TextStyle(
                        color: isLocked ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isFeatured ? 16 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isFeatured ? 18 : 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  maxLines: isFeatured ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isFeatured ? 14 : 12,
                    color: Colors.white.withValues(alpha: 0.5),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    onPressed: (canAfford && !isLocked)
                        ? () => _redeemReward(reward)
                        : null,
                    label: isLocked
                        ? 'Unlock at $requiredTier'
                        : (canAfford
                            ? (isFeatured ? 'Redeem Now' : 'Redeem')
                            : 'Not Enough'),
                    variant: (canAfford && !isLocked)
                        ? AppButtonVariant.primary
                        : AppButtonVariant.outline,
                    size: isFeatured ? AppButtonSize.md : AppButtonSize.sm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.colors.glassDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: DesignTokens.colors.accentGreen.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.heart,
                color: DesignTokens.colors.accentGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Support Cyber Victims',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Donate 200 pts to provide legal aid to victims.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: [
                      Text(
                        'Donate Now',
                        style: TextStyle(
                          color: DesignTokens.colors.accentGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Icon(LucideIcons.arrowRight,
                          size: 12, color: DesignTokens.colors.accentGreen),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _calculateTierName(int totalPoints) {
    if (totalPoints >= 10000) return 'Diamond Protector';
    if (totalPoints >= 5000) return 'Gold Protector';
    if (totalPoints >= 1000) return 'Silver Protector';
    return 'Bronze Protector';
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
                color: Colors.white54, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double height;
  const _Skeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

