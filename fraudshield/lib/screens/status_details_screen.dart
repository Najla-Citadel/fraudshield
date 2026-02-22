import 'package:flutter/material.dart';
import '../constants/colors.dart';

class StatusDetailsScreen extends StatelessWidget {
  const StatusDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Status Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                _buildShieldHero(),
                const SizedBox(height: 40),
                _buildTierProgress(),
                const SizedBox(height: 48),
                _buildBenefitSection(
                  title: 'CURRENT BENEFITS',
                  benefits: [
                    _BenefitItem(
                      icon: Icons.trending_up_rounded,
                      title: '5% Points Bonus on Reports',
                      subtitle: 'Earn more for every verified scam report',
                      isLocked: false,
                    ),
                    _BenefitItem(
                      icon: Icons.card_giftcard_rounded,
                      title: 'Silver-Exclusive Rewards',
                      subtitle: 'Access to the silver-tier marketplace',
                      isLocked: false,
                    ),
                    _BenefitItem(
                      icon: Icons.verified_user_rounded,
                      title: 'Priority Community Verification',
                      subtitle: 'Your votes carry 2x more weight',
                      isLocked: false,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                _buildBenefitSection(
                  title: 'LOCKED AT GOLD',
                  benefits: [
                    _BenefitItem(
                      icon: Icons.security_rounded,
                      title: '10% Points Bonus',
                      subtitle: 'Double your current efficiency',
                      isLocked: true,
                    ),
                    _BenefitItem(
                      icon: Icons.support_agent_rounded,
                      title: 'Direct Support Access',
                      subtitle: '24/7 priority human assistance',
                      isLocked: true,
                    ),
                    _BenefitItem(
                      icon: Icons.label_important_outline_rounded,
                      title: 'Premium Feature Discounts',
                      subtitle: '30% off all protection add-ons',
                      isLocked: true,
                    ),
                  ],
                ),
                const SizedBox(height: 120), // Bottom padding for fixed button
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: _buildHowToLevelUpButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildShieldHero() {
    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.0),
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E293B),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Silver Protector',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accentGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ACTIVE STATUS',
                style: TextStyle(
                  color: AppColors.accentGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTierProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tier Progress',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '450 XP to Gold Protector',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              'Level 12',
              style: TextStyle(
                color: AppColors.accentGreen,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 0.65,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.05),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _tierLabel('BRONZE'),
            _tierLabel('SILVER', isActive: true),
            _tierLabel('GOLD'),
          ],
        ),
      ],
    );
  }

  Widget _tierLabel(String label, {bool isActive = false}) {
    return Text(
      label,
      style: TextStyle(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildBenefitSection({required String title, required List<_BenefitItem> benefits}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: benefits.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _buildBenefitTile(item),
                  if (index < benefits.length - 1)
                    Divider(
                      height: 1,
                      color: Colors.white.withOpacity(0.05),
                      indent: 70,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitTile(_BenefitItem item) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.isLocked 
                  ? Colors.white.withOpacity(0.05)
                  : AppColors.accentGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: item.isLocked 
                  ? Colors.white.withOpacity(0.2)
                  : AppColors.accentGreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: item.isLocked ? Colors.white.withOpacity(0.4) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!item.isLocked)
            const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 20)
          else
            Icon(Icons.lock_rounded, color: Colors.white.withOpacity(0.2), size: 18),
        ],
      ),
    );
  }

  Widget _buildHowToLevelUpButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.accentGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Text(
              'How to Level Up',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLocked;

  _BenefitItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLocked,
  });
}
