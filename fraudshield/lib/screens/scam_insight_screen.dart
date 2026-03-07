import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_divider.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import 'scam_map_screen.dart';
import '../widgets/glass_surface.dart';

class ScamInsightScreen extends StatefulWidget {
  const ScamInsightScreen({super.key});

  @override
  State<ScamInsightScreen> createState() => _ScamInsightScreenState();
}

class _ScamInsightScreenState extends State<ScamInsightScreen> {
  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Scam Insights',
      actions: [
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(LucideIcons.filter, color: Colors.white, size: 18),
          label: const Text(
            'Filter',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.lg, vertical: DesignTokens.spacing.xl),
        children: [
          const _RiskLevelCard(),
          const SizedBox(height: 16),
          const _TrendingHeroCard(),
          const SizedBox(height: 16),
          const _DistributionChartCard(),
          const SizedBox(height: 16),
          const _AIPatternBanner(),
          const SizedBox(height: 16),
          const _LocalActivityCard(),
          const SizedBox(height: 24),
          Text(
            'Learn to Stay Safe',
            style: TextStyle(
              color: DesignTokens.colors.textLight,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const _EducationCarousel(),
          const SizedBox(height: 24),
          const _RecentFeedList(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _RiskLevelCard extends StatelessWidget {
  const _RiskLevelCard();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: EdgeInsets.all(DesignTokens.spacing.lg),
      borderRadius: DesignTokens.radii.lg,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: DesignTokens.colors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(color: DesignTokens.colors.textLight, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                  children: const [
                    TextSpan(text: 'Today\'s Risk Level: '),
                    TextSpan(text: '🔴 Elevated', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Scam reports up 18% in the last 24 hours',
                style: TextStyle(color: DesignTokens.colors.textLight.withOpacity(0.5), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendingHeroCard extends StatelessWidget {
  const _TrendingHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
        gradient: LinearGradient(
          colors: [DesignTokens.colors.primary.withOpacity(0.8), DesignTokens.colors.primary.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: DesignTokens.shadows.md,
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(DesignTokens.spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      '🔥 #1 Trending Scam',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Parcel Delivery Fee Scam',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const _MetricRow(icon: LucideIcons.trendingUp, text: '34% This Week', iconColor: Colors.yellow),
                const SizedBox(height: 8),
                const _MetricRow(icon: LucideIcons.mail, text: '412 Reports'),
                const SizedBox(height: 8),
                const _MetricRow(icon: LucideIcons.coins, text: 'Avg Loss: RM1,200', iconColor: Colors.amber),
                const SizedBox(height: 8),
                const _MetricRow(icon: LucideIcons.mapPin, text: 'Klang Valley Targeted', iconColor: Colors.orangeAccent),
                
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radii.lg)),
                      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.lg, vertical: DesignTokens.spacing.sm),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Learn How It Works', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        SizedBox(width: 4),
                        Icon(LucideIcons.chevronRight, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -20,
            top: 20,
            child: Opacity(
              opacity: 0.9,
              child: Icon(
                LucideIcons.package,
                size: 140,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;

  const _MetricRow({required this.icon, required this.text, this.iconColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DistributionChartCard extends StatelessWidget {
  const _DistributionChartCard();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: EdgeInsets.all(DesignTokens.spacing.xl),
      borderRadius: DesignTokens.radii.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scam Type Distribution',
            style: TextStyle(
              color: DesignTokens.colors.textLight,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _LegendItem(color: DesignTokens.colors.primary, label: 'Loan Scam', value: '32%', icon: '💰'),
                    const SizedBox(height: 12),
                    _LegendItem(color: DesignTokens.colors.accentGreen, label: 'Love Scam', value: '25%', icon: '❤️'),
                    const SizedBox(height: 12),
                    _LegendItem(color: DesignTokens.colors.surfaceDark, label: 'Parcel Scam', value: '18%', icon: '📦'),
                    const SizedBox(height: 12),
                    _LegendItem(color: Colors.indigo, label: 'Investment Scam', value: '15%', icon: '📈'),
                    const SizedBox(height: 12),
                    _LegendItem(color: Colors.blue, label: 'QR Scams', value: '10%', icon: '📍'),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 160,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: Colors.blue.withOpacity(0.7),
                          value: 10,
                          title: '',
                          radius: 30,
                        ),
                        PieChartSectionData(
                          color: Colors.indigo.withOpacity(0.7),
                          value: 15,
                          title: '15%',
                          radius: 30,
                          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: DesignTokens.colors.surfaceDark.withOpacity(0.7),
                          value: 18,
                          title: '18%',
                          radius: 30,
                          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: DesignTokens.colors.accentGreen.withOpacity(0.7),
                          value: 25,
                          title: '25%',
                          radius: 30,
                          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: DesignTokens.colors.primary.withOpacity(0.7),
                          value: 32,
                          title: '32%',
                          radius: 30,
                          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String icon;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: DesignTokens.colors.textLight),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: DesignTokens.colors.textLight.withOpacity(0.5), fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _AIPatternBanner extends StatelessWidget {
  const _AIPatternBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
        gradient: LinearGradient(
          colors: [DesignTokens.colors.primary, DesignTokens.colors.primary.withOpacity(0.6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.bot, color: DesignTokens.colors.accentGreen, size: 20),
              const SizedBox(width: 8),
              const Text(
                'AI Detected New Pattern',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Fake TNG QR codes with courier logos found!',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('View Details ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Icon(LucideIcons.chevronRight, color: Colors.white, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalActivityCard extends StatelessWidget {
  const _LocalActivityCard();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: EdgeInsets.all(DesignTokens.spacing.xl),
      borderRadius: DesignTokens.radii.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.mapPin, color: DesignTokens.colors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Your Area: High Scam Activity',
                style: TextStyle(
                  color: DesignTokens.colors.textLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: DesignTokens.spacing.md),
            child: AppDivider(thickness: 1, color: Colors.white.withOpacity(0.1)),
          ),
          Text(
            'Loan approval scam on the rise locally.',
            style: TextStyle(
              color: DesignTokens.colors.textLight.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScamMapScreen()),
              );
            },
            label: 'View Malaysia Heatmap',
            icon: LucideIcons.chevronRight,
            variant: AppButtonVariant.primary,
          ),
        ],
      ),
    );
  }
}

class _EducationCarousel extends StatelessWidget {
  const _EducationCarousel();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: const [
          _EduCard(title: 'How Macau Scams\nWork', color: Color(0xFF1E293B)),
          SizedBox(width: 12),
          _EduCard(title: 'QR Code Scam\nTricks', color: Color(0xFF334155), hasQr: true),
          SizedBox(width: 12),
          _EduCard(title: 'Signs of a Scam Call', color: Color(0xFF475569)),
        ],
      ),
    );
  }
}

class _EduCard extends StatelessWidget {
  final String title;
  final Color color;
  final bool hasQr;

  const _EduCard({required this.title, required this.color, this.hasQr = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DesignTokens.radii.md),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(DesignTokens.spacing.md),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (hasQr)
            Positioned(
              bottom: 8,
              right: 8,
              child: Icon(LucideIcons.qrCode, color: Colors.white.withOpacity(0.3), size: 20),
            )
          else
            Positioned(
              bottom: 8,
              left: 8,
              child: Icon(LucideIcons.user, color: Colors.white.withOpacity(0.2), size: 24),
            )
        ],
      ),
    );
  }
}

class _RecentFeedList extends StatelessWidget {
  const _RecentFeedList();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: EdgeInsets.zero,
      borderRadius: DesignTokens.radii.lg,
      child: Column(
        children: [
          _FeedItem(icon: LucideIcons.messageSquare, title: 'New scam number', subtitle: 'reported', time: '2h ago', color: Colors.orange),
          const AppDivider(height: 1, color: Colors.white10),
          _FeedItem(icon: LucideIcons.mail, title: 'Fake bank SMS', subtitle: 'alert', time: '5h ago', color: DesignTokens.colors.primary),
          const AppDivider(height: 1, color: Colors.white10),
          _FeedItem(icon: LucideIcons.shoppingBag, title: 'Shopee refund call', subtitle: 'scam', time: '8h ago', color: Colors.orange.shade700),
        ],
      ),
    );
  }
}

class _FeedItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _FeedItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacing.lg),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                children: [
                  TextSpan(text: '$title ', style: TextStyle(fontWeight: FontWeight.bold, color: DesignTokens.colors.textLight)),
                  TextSpan(text: subtitle, style: TextStyle(color: DesignTokens.colors.textLight.withOpacity(0.5))),
                ],
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(color: DesignTokens.colors.textLight.withOpacity(0.3), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
