import 'dart:developer';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'points_history_screen.dart';
import 'badges_screen.dart';
import '../models/badge_model.dart';
import 'package:fraudshield/constants/colors.dart';

import '../widgets/glass_card.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => PointsScreenState();
}

class PointsScreenState extends State<PointsScreen> {
  final ApiService _api = ApiService.instance;
  bool _loading = true;
  int _balance = 0;
  String _selectedCategory = 'All Rewards';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> refreshData() async {
    await _loadPoints();
    if (mounted) setState(() {});
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    await _loadPoints();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadPoints() async {
    try {
      final res = await _api.getMyPoints();
      _balance = res['totalPoints'] ?? 0;
    } catch (e) {
      log('Error loading points: $e');
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Balance Card
                  _buildBalanceCard(),
                  const SizedBox(height: 24),

                  // 2. Badges Strip
                  _buildBadgesStrip(),
                  const SizedBox(height: 24),

                  // 3. Category Selector
                  _buildCategorySelector(),
                  const SizedBox(height: 24),


                  // 3. Sections
                  _buildSectionHeader('Security Upgrades'),
                  const SizedBox(height: 12),
                  _buildFeaturedReward(),
                  
                  const SizedBox(height: 32),
                  
                  _buildSectionHeader('Digital Vouchers'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildVoucherCard(
                          icon: Icons.local_taxi,
                          amount: 'RM10',
                          title: 'Grab Voucher',
                          cost: 1000,
                          desc: 'RM10 off your next ride or food delivery.',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildVoucherCard(
                          icon: Icons.local_cafe,
                          amount: 'RM15',
                          title: 'Starbucks Credit',
                          cost: 850,
                          desc: 'A fresh brew on us. Enjoy a drink.',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  _buildDonationCard(),
                  
                  const SizedBox(height: 100), // Bottom padding for FAB
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
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
                'YOUR BALANCE',
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
                  text: '$_balance',
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
          const SizedBox(height: 16),
          Text(
            'You\'ve reached Silver Protector status this month. Keep it up!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _categoryChip('All Rewards', isActive: _selectedCategory == 'All Rewards'),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentGreen : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black87 : Colors.white,
            fontWeight: FontWeight.w600,
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

  Widget _buildFeaturedReward() {
    // Large featured card - keeping custom styling as it's unique, but using consistent colors
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Match GlassCard base
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Icon Area
          Container(
            height: 140,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
               gradient: LinearGradient(
                  colors: [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.05)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
               ),
               borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(Icons.security, size: 80, color: Colors.blue.withOpacity(0.5)),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '500 PTS',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1-Month Premium',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Full access to AI-powered transaction monitoring and priority alerts.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentGreen,
                      side: const BorderSide(color: AppColors.accentGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Redeem Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard({
    required IconData icon,
    required String amount,
    required String title,
    required int cost,
    required String desc,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Container(
                 padding: const EdgeInsets.all(10),
                 decoration: BoxDecoration(
                   color: Colors.white.withOpacity(0.1),
                   shape: BoxShape.circle,
                 ),
                 child: Icon(icon, color: Colors.white, size: 20),
               ),
               Text(
                 '$cost PTS',
                 style: const TextStyle(
                   color: AppColors.accentGreen,
                   fontSize: 12,
                   fontWeight: FontWeight.bold,
                 ),
               ),
             ],
           ),
           const SizedBox(height: 16),
           Text(
             title,
             style: const TextStyle(
               color: Colors.white,
               fontWeight: FontWeight.bold,
               fontSize: 14,
             ),
           ),
           const SizedBox(height: 4),
           Text(
             desc,
             style: TextStyle(
               color: Colors.white.withOpacity(0.5),
               fontSize: 11,
               height: 1.3,
             ),
             maxLines: 2,
             overflow: TextOverflow.ellipsis,
           ),
           const SizedBox(height: 16),
           SizedBox(
             width: double.infinity,
             child: OutlinedButton(
               onPressed: () {},
               style: OutlinedButton.styleFrom(
                 foregroundColor: Colors.white,
                 side: BorderSide(color: Colors.white.withOpacity(0.2)),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 padding: const EdgeInsets.symmetric(vertical: 10),
               ),
               child: const Text('Claim', style: TextStyle(fontSize: 12)),
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

  Widget _buildBadgesStrip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MY BADGES',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BadgesScreen()),
              ),
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildBadgeStripItem('🎯'),
              _buildBadgeStripItem('🛡️'),
              _buildBadgeStripItem('💎'),
              _buildBadgeStripItem('🔥'),
              _buildBadgeStripItem('⚖️'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeStripItem(String icon) {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      alignment: Alignment.center,
      child: Text(icon, style: const TextStyle(fontSize: 24)),
    );
  }
}

