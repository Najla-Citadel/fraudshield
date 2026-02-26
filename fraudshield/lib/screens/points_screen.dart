import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'points_history_screen.dart';
import 'badges_screen.dart';
import 'points_details_screen.dart';
import '../models/badge_model.dart';
import 'package:fraudshield/constants/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/error_state.dart';

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
          _rewards = List<Map<String, dynamic>>.from(rewardsRes['results'] as List);
          _userTier = rewardsRes['userTier'] ?? 'BRONZE';
          _userDiscount = (rewardsRes['userDiscount'] ?? 0).toDouble();
        });
      }
      // Sync auth provider to get latest balance/profile
      await context.read<AuthProvider>().refreshProfile();
    } catch (e) {
      log('Error loading points/rewards: $e');
      if (e.toString().contains('403')) {
        // likely email not verified, profiles sync failed but we let it pass
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient points!'), backgroundColor: Colors.red));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Redeem ${reward['name']}?'),
        content: Text('Cost: $pointsCost points\nYour balance after: ${points - pointsCost} points'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.redeemReward(reward['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Redeemed ${reward['name']}!'), backgroundColor: Colors.green));
        // Refresh local rewards AND global balance
        await context.read<AuthProvider>().refreshProfile();
        refreshData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        title: const Text('Rewards', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: IconButton(
              icon: const Icon(Icons.history_rounded, size: 20, color: Colors.white),
              onPressed: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PointsHistoryScreen()),
                );
              },
              tooltip: 'History',
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return ErrorState(onRetry: refreshData);
    }

    if (_loading) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SkeletonCard(height: 180, margin: EdgeInsets.zero),
            const SizedBox(height: 24),
            const SkeletonCard(height: 100, margin: EdgeInsets.zero),
            const SizedBox(height: 24),
            const SkeletonCard(height: 250, margin: EdgeInsets.zero),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Balance Card
          _buildBalanceCard(),
          const SizedBox(height: 16),

          // 2. Category Selector
          _buildCategorySelector(),
          const SizedBox(height: 16),

          // 3. Sections
          if (_selectedCategory == 'All' || _selectedCategory == 'Security') ...[
            _buildSectionHeader('Security Upgrades'),
            const SizedBox(height: 12),
            ..._rewards
                .where((r) => r['type'].toString().toUpperCase() == 'SUBSCRIPTION')
                .map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildFeaturedReward(r),
                    ))
                .toList(),
            if (_rewards.where((r) => r['type'].toString().toUpperCase() == 'SUBSCRIPTION').isEmpty)
              const Text('No security upgrades available', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 32),
          ],
          
          if (_selectedCategory == 'All' || _selectedCategory == 'Vouchers') ...[
            _buildSectionHeader('Store Items & Vouchers'),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 260, // Fixed height for consistency
              ),
              itemCount: _rewards.where((r) => r['type'].toString().toUpperCase() != 'SUBSCRIPTION').length,
              itemBuilder: (context, index) {
                final r = _rewards.where((r) => r['type'].toString().toUpperCase() != 'SUBSCRIPTION').toList()[index];
                return _buildRewardCard(r, false);
              },
            ),
            if (_rewards.where((r) => r['type'].toString().toUpperCase() != 'SUBSCRIPTION').isEmpty)
              const Text('No store items available', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 32),
          ],

          _buildDonationCard(),
          
          const SizedBox(height: 100), // Bottom padding for FAB
        ],
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
          color: const Color(0xFF0F2633), // Dark Teal/Navy
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F2633), Color(0xFF0A1A24)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'AVAILABLE BALANCE',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accentGreen,
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
                      color: AppColors.accentGreen.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (_userDiscount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_offer_rounded, size: 14, color: AppColors.accentGreen),
                    const SizedBox(width: 6),
                    Text(
                      '${(_userDiscount * 100).toInt()}% $_userTier Discount Active',
                      style: const TextStyle(
                        color: AppColors.accentGreen,
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
                color: Colors.white.withOpacity(0.7),
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
          _categoryChip('All', isActive: _selectedCategory == 'All'),
          const SizedBox(width: 12),
          _categoryChip('Vouchers', isActive: _selectedCategory == 'Vouchers'),
          const SizedBox(width: 12),
          _categoryChip('Security', isActive: _selectedCategory == 'Security'),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, {bool isActive = false}) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentGreen : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(22),
          border: isActive ? null : Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black87 : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
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
              color: AppColors.accentGreen,
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(isFeatured ? 24 : 20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual Area
          Container(
            height: isFeatured ? 140 : 100,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isFeatured 
                  ? [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.05)]
                  : [AppColors.accentGreen.withOpacity(0.1), AppColors.accentGreen.withOpacity(0.02)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(isFeatured ? 24 : 20)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    isLocked ? Icons.lock_outline_rounded : (isFeatured ? Icons.security : Icons.card_giftcard), 
                    size: isFeatured ? 64 : 40, 
                    color: isLocked ? Colors.white24 : (isFeatured ? Colors.blue.withOpacity(0.5) : AppColors.accentGreen.withOpacity(0.5)),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLocked ? Colors.black54 : AppColors.accentGreen,
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
          
          // Content Area
          Padding(
            padding: EdgeInsets.all(isFeatured ? 20 : 16),
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
                    color: Colors.white.withOpacity(0.5),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: (canAfford && !isLocked) ? () => _redeemReward(reward) : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isFeatured ? AppColors.accentGreen : Colors.white,
                      side: BorderSide(
                        color: (canAfford && !isLocked) 
                          ? (isFeatured ? AppColors.accentGreen : Colors.white.withOpacity(0.3))
                          : Colors.white.withOpacity(0.05)
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: isFeatured ? 14 : 10),
                    ),
                    child: Text(
                      isLocked 
                        ? 'Unlock at $requiredTier' 
                        : (canAfford ? (isFeatured ? 'Redeem Now' : 'Redeem') : 'Not Enough'), 
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: (canAfford && !isLocked) 
                          ? (isFeatured ? AppColors.accentGreen : Colors.white) 
                          : Colors.white.withOpacity(0.3)
                      )
                    ),
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
    return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.2), // Darker teal
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volunteer_activism, color: AppColors.accentGreen),
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
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: (){},
                    child: Row(
                      children: const [
                         Text(
                          'Donate Now',
                          style: TextStyle(
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Icon(Icons.arrow_forward, size: 12, color: AppColors.accentGreen),
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
}

