import 'dart:developer';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/badge_model.dart';
import '../constants/colors.dart';
import '../widgets/glass_card.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final ApiService _api = ApiService.instance;
  bool _loading = true;
  List<BadgeModel> _earned = [];
  List<BadgeModel> _available = [];
  String _selectedTier = 'All';

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getMyBadges();
      if (mounted) {
        setState(() {
          _earned = (res['earned'] as List? ?? [])
              .map((e) => BadgeModel.fromJson(e))
              .toList();
          _available = (res['available'] as List? ?? [])
              .map((e) => BadgeModel.fromJson(e))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      log('Error loading badges: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<BadgeModel> get _allBadges => [..._earned, ..._available];

  List<BadgeModel> get _filteredBadges {
    if (_selectedTier == 'All') return _allBadges;
    return _allBadges.where((b) => b.tier.toLowerCase() == _selectedTier.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        title: const Text('My Badges', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBadges,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                    _buildTierFilter(),
                    const SizedBox(height: 24),
                    _buildBadgeGrid(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: _allBadges.isEmpty ? 0 : _earned.length / _allBadges.length,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_earned.length}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    '/${_allBadges.length}',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collection Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'You\'ve unlocked ${(_allBadges.isEmpty ? 0 : (_earned.length / _allBadges.length * 100).toInt())}% of all security badges.',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierFilter() {
    final tiers = ['All', 'Bronze', 'Silver', 'Gold', 'Platinum'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tiers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final tier = tiers[index];
          final isActive = _selectedTier == tier;
          return GestureDetector(
            onTap: () => setState(() => _selectedTier = tier),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? AppColors.accentGreen : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: isActive ? null : Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                tier,
                style: TextStyle(
                  color: isActive ? Colors.black87 : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgeGrid() {
    if (_filteredBadges.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(
            'No $_selectedTier badges yet.',
            style: TextStyle(color: Colors.white.withOpacity(0.4)),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _filteredBadges.length,
      itemBuilder: (context, index) {
        final badge = _filteredBadges[index];
        return _buildBadgeCard(badge);
      },
    );
  }

  Widget _buildBadgeCard(BadgeModel badge) {
    Color tierColor;
    switch (badge.tier.toLowerCase()) {
      case 'platinum': tierColor = Colors.cyanAccent; break;
      case 'gold': tierColor = Colors.amber; break;
      case 'silver': tierColor = Colors.blueGrey.shade200; break;
      case 'bronze': 
      default: tierColor = Colors.orangeAccent.shade100; break;
    }

    return GestureDetector(
      onTap: () => _showBadgeDetail(badge),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: badge.isEarned ? tierColor.withOpacity(0.1) : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: badge.isEarned ? tierColor.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow for earned badges
                  if (badge.isEarned)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: tierColor.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  
                  // Icon
                  Text(
                    badge.icon,
                    style: TextStyle(
                      fontSize: 32,
                      color: badge.isEarned ? null : Colors.white.withOpacity(0.1),
                    ),
                  ),

                  // Lock overlay
                  if (!badge.isEarned)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Icon(Icons.lock, size: 14, color: Colors.white.withOpacity(0.2)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: badge.isEarned ? FontWeight.bold : FontWeight.normal,
              color: badge.isEarned ? Colors.white : Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showBadgeDetail(BadgeModel badge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _BadgeDetailSheet(badge: badge),
    );
  }
}

class _BadgeDetailSheet extends StatelessWidget {
  final BadgeModel badge;
  const _BadgeDetailSheet({required this.badge});

  @override
  Widget build(BuildContext context) {
    Color tierColor;
    switch (badge.tier.toLowerCase()) {
      case 'platinum': tierColor = Colors.cyanAccent; break;
      case 'gold': tierColor = Colors.amber; break;
      case 'silver': tierColor = Colors.blueGrey.shade200; break;
      case 'bronze': 
      default: tierColor = Colors.orangeAccent.shade100; break;
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          
          // Large Badge Icon
          Container(
            width: 100,
            height: 100,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badge.isEarned ? tierColor.withOpacity(0.1) : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: badge.isEarned ? tierColor.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                width: 2,
              ),
            ),
            child: Text(
              badge.icon,
              style: TextStyle(
                fontSize: 48,
                color: badge.isEarned ? null : Colors.white.withOpacity(0.2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            badge.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: tierColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badge.tier.toUpperCase(),
              style: TextStyle(
                color: tierColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7), height: 1.5),
          ),
          
          const SizedBox(height: 32),
          
          if (badge.isEarned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, color: AppColors.accentGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Unlocked',
                    style: TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                Text(
                  'HOW TO EARN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.4),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getEarningInstruction(badge),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.05),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Close'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _getEarningInstruction(BadgeModel badge) {
    final threshold = badge.threshold ?? 0;
    switch (badge.trigger) {
      case 'reports':
        return 'Submit $threshold public scam reports to the community.';
      case 'verifications':
        return 'Verify $threshold scam reports submitted by others.';
      case 'reputation':
        return 'Reach a trust reputation score of $threshold.';
      case 'streak':
        return 'Log in for $threshold consecutive days.';
      default:
        return 'Complete special community challenges.';
    }
  }
}
