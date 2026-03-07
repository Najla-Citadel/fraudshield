import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design_system/tokens/design_tokens.dart';
import '../providers/auth_provider.dart';

class StatusDetailsScreen extends StatelessWidget {
  const StatusDetailsScreen({super.key});

  String _calculateTier(int totalPoints) {
    if (totalPoints >= 10000) return 'Diamond';
    if (totalPoints >= 5000) return 'Gold';
    if (totalPoints >= 1000) return 'Silver';
    return 'Bronze';
  }

  double _calculateProgress(int totalPoints) {
    if (totalPoints >= 10000) return 1.0;
    if (totalPoints >= 5000) return (totalPoints - 5000) / 5000;
    if (totalPoints >= 1000) return (totalPoints - 1000) / 4000;
    return totalPoints / 1000;
  }

  String _getNextTierInfo(int totalPoints) {
    if (totalPoints >= 10000) return 'Max Tier Reached';
    if (totalPoints >= 5000) return '${10000 - totalPoints} PTS to Diamond Protector';
    if (totalPoints >= 1000) return '${5000 - totalPoints} PTS to Gold Protector';
    return '${1000 - totalPoints} PTS to Silver Protector';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final totalPoints = authProvider.user?.profile?.totalPoints ?? 0;
    final tier = _calculateTier(totalPoints);

    return Scaffold(
      backgroundColor: DesignTokens.colors.backgroundDark,
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
                _buildShieldHero(tier),
                const SizedBox(height: 40),
                _buildTierProgress(totalPoints),
                const SizedBox(height: 48),
                _buildBenefitSection(
                  title: 'CURRENT BENEFITS',
                  benefits: _getBenefitsForTier(tier, true),
                ),
                const SizedBox(height: 40),
                if (tier != 'Diamond')
                  _buildBenefitSection(
                    title: 'LOCKED AT ${_getNextTierName(tier)}',
                    benefits: _getBenefitsForTier(_getNextTierName(tier).toLowerCase(), false),
                  ),
                const SizedBox(height: 120),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: _buildHowToLevelUpButton(context),
          ),
        ],
      ),
    );
  }

  String _getNextTierName(String currentTier) {
    switch (currentTier) {
      case 'Bronze': return 'SILVER';
      case 'Silver': return 'GOLD';
      case 'Gold': return 'DIAMOND';
      default: return 'MAX';
    }
  }

  List<_BenefitItem> _getBenefitsForTier(String tier, bool unlocked) {
    tier = tier.toLowerCase();
    if (tier == 'bronze') {
      return [
        _BenefitItem(
          icon: Icons.trending_up_rounded,
          title: 'Basic Points Earning',
          subtitle: 'Earn standard points for reports',
          isLocked: !unlocked,
        ),
      ];
    } else if (tier == 'silver') {
      return [
        _BenefitItem(
          icon: Icons.trending_up_rounded,
          title: '5% Points Bonus',
          subtitle: 'Earn more for every verified scam report',
          isLocked: !unlocked,
        ),
        _BenefitItem(
          icon: Icons.verified_user_rounded,
          title: 'Priority Verification',
          subtitle: 'Your votes carry 1.5x more weight',
          isLocked: !unlocked,
        ),
      ];
    } else if (tier == 'gold') {
      return [
        _BenefitItem(
          icon: Icons.security_rounded,
          title: '10% Points Bonus',
          subtitle: 'Double your current efficiency',
          isLocked: !unlocked,
        ),
        _BenefitItem(
          icon: Icons.support_agent_rounded,
          title: 'Direct Support Access',
          subtitle: 'Priority human assistance',
          isLocked: !unlocked,
        ),
      ];
    } else if (tier == 'diamond') {
      return [
        _BenefitItem(
          icon: Icons.diamond_rounded,
          title: '25% Points Bonus',
          subtitle: 'Maximum efficiency tier',
          isLocked: !unlocked,
        ),
        _BenefitItem(
          icon: Icons.stars_rounded,
          title: 'Early Access',
          subtitle: 'Test new security features first',
          isLocked: !unlocked,
        ),
        _BenefitItem(
          icon: Icons.card_membership_rounded,
          title: 'Diamond Protector Badge',
          subtitle: 'Elite status on your public profile',
          isLocked: !unlocked,
        ),
      ];
    }
    return [];
  }

  Widget _buildShieldHero(String tier) {
    Color tierColor;
    switch (tier) {
      case 'Diamond': tierColor = Colors.cyan; break;
      case 'Gold': tierColor = Colors.amber; break;
      case 'Silver': tierColor = Colors.grey.shade400; break;
      default: tierColor = Colors.orange.shade700;
    }

    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                tierColor.withOpacity(0.2),
                tierColor.withOpacity(0.0),
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
              child: Icon(
                Icons.shield_rounded,
                size: 60,
                color: tierColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '$tier Protector',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: DesignTokens.colors.accentGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DesignTokens.colors.accentGreen.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: DesignTokens.colors.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ACTIVE STATUS',
                style: TextStyle(
                  color: DesignTokens.colors.accentGreen,
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

  Widget _buildTierProgress(int totalPoints) {
    final progress = _calculateProgress(totalPoints);
    final nextTierInfo = _getNextTierInfo(totalPoints);

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
                Text(
                  nextTierInfo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              '$totalPoints Total PTS',
              style: TextStyle(
                color: DesignTokens.colors.accentGreen,
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
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.colors.accentGreen),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _tierLabel('BRONZE', isActive: totalPoints < 1000),
            _tierLabel('SILVER', isActive: totalPoints >= 1000 && totalPoints < 5000),
            _tierLabel('GOLD', isActive: totalPoints >= 5000 && totalPoints < 10000),
            _tierLabel('DIAMOND', isActive: totalPoints >= 10000),
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
                  : DesignTokens.colors.accentGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: item.isLocked 
                  ? Colors.white.withOpacity(0.2)
                  : DesignTokens.colors.accentGreen,
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
            Icon(Icons.check_circle_rounded, color: DesignTokens.colors.accentGreen, size: 20)
          else
            Icon(Icons.lock_rounded, color: Colors.white.withOpacity(0.2), size: 18),
        ],
      ),
    );
  }

  Widget _buildHowToLevelUpButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: DesignTokens.colors.accentGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.colors.accentGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showLevelUpGuide(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Text(
              'How to Earn Points',
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

  void _showLevelUpGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How to Earn Points',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _guideItem(Icons.report_problem_rounded, 'Submit a Scam Report', '10 Points'),
            _guideItem(Icons.verified_rounded, 'Verify Others\' Reports', '5 Points'),
            _guideItem(Icons.login_rounded, 'Daily Login Streak', '2-10 Points'),
            _guideItem(Icons.share_rounded, 'Share Security Alerts', '5 Points'),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Got it!', style: TextStyle(color: DesignTokens.colors.accentGreen, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideItem(IconData icon, String title, String points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: DesignTokens.colors.accentGreen, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
          Text(points, style: TextStyle(color: DesignTokens.colors.accentGreen, fontWeight: FontWeight.bold)),
        ],
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
