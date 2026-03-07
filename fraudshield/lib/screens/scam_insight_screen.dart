import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../design_system/components/app_button.dart';
import 'scam_map_screen.dart';

class ScamInsightScreen extends StatefulWidget {
  const ScamInsightScreen({super.key});

  @override
  State<ScamInsightScreen> createState() => _ScamInsightScreenState();
}

class _ScamInsightScreenState extends State<ScamInsightScreen> {
  // We'll keep the scaffold background slightly off-white as per the mockup
  final Color _bgColor = const Color(0xFFF3F4F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Scam Insights',
          style: TextStyle(
            color: Color(0xFF1E3A8A), // Deep blue matching the text
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Text(
              'Filter',
              style: TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w600,
              ),
            ),
            label: const Icon(LucideIcons.chevronDown, color: Color(0xFF1E3A8A), size: 18),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
          const Text(
            'Learn to Stay Safe',
            style: TextStyle(
              color: Color(0xFF1E3A8A),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const _EducationCarousel(),
          const SizedBox(height: 24),
          const _RecentFeedList(),
        ],
      ),
    );
  }
}

class _RiskLevelCard extends StatelessWidget {
  const _RiskLevelCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange.shade400,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                  children: [
                    TextSpan(text: 'Today\'s Risk Level: '),
                    TextSpan(text: '🔴 Elevated', style: TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Scam reports up 18% in the last 24 hours',
                style: TextStyle(color: Colors.grey, fontSize: 13),
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
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFDC2626)], // Orange to Red
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
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
                _MetricRow(icon: LucideIcons.trendingUp, text: '34% This Week', iconColor: Colors.yellow),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // Illustration mock (using a box icon since we don't have the 3D asset)
          Positioned(
            right: -20,
            top: 20,
            child: Opacity(
              opacity: 0.9,
              child: Icon(
                LucideIcons.package,
                size: 140,
                color: Colors.white.withOpacity(0.2),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scam Type Distribution',
            style: TextStyle(
              color: Color(0xFF1E3A8A),
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
                    _LegendItem(color: Colors.orange.shade600, label: 'Loan Scam', value: '32%', icon: '📦'),
                    const SizedBox(height: 12),
                    const _LegendItem(color: Colors.redAccent, label: 'Love Scam', value: '25%', icon: '❤️'),
                    const SizedBox(height: 12),
                    _LegendItem(color: Colors.orange.shade300, label: 'Parcel Scam', value: '18%', icon: '📦'),
                    const SizedBox(height: 12),
                    const _LegendItem(color: Colors.indigo, label: 'Investment Scam', value: '15%', icon: '📈'),
                    const SizedBox(height: 12),
                    const _LegendItem(color: Colors.blue, label: 'QR Scams', value: '10%', icon: '📍'),
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
                          color: Colors.blue,
                          value: 10,
                          title: '',
                          radius: 30,
                        ),
                        PieChartSectionData(
                          color: Colors.indigo,
                          value: 15,
                          title: '15%',
                          radius: 30,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: Colors.blue.shade600, // Replacing orange.shade300 for varied color as in mockup
                          value: 18,
                          title: '18%',
                          radius: 30,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: Colors.orange.shade400, // Replacing redAccent
                          value: 25,
                          title: '25%',
                          radius: 30,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: Colors.orange.shade700, // Replacing orange.shade600
                          value: 32,
                          title: '32%',
                          radius: 30,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)], // Deep blue to sky blue
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        image: const DecorationImage(
          image: NetworkImage('https://www.transparenttextures.com/patterns/stardust.png'), // Mock starry effect
          fit: BoxFit.cover,
          opacity: 0.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.bot, color: Colors.cyanAccent, size: 20),
              SizedBox(width: 8),
              Text(
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
              color: Colors.white,
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.mapPin, color: Colors.redAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Your Area: High Scam Activity',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF3F4F6), thickness: 2),
          ),
          const Text(
            'Loan approval scam on the rise locally.',
            style: TextStyle(
              color: Colors.black87,
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
        children: [
          _EduCard(title: 'How Macau Scams\nWork', color: Colors.blueGrey.shade800),
          const SizedBox(width: 12),
          _EduCard(title: 'QR Code Scam\nTricks', color: Colors.blueGrey.shade700, hasQr: true),
          const SizedBox(width: 12),
          _EduCard(title: 'Signs of a Scam Call', color: Colors.brown.shade800),
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
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'), // Subtle texture
          opacity: 0.1,
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
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
          if (hasQr)
            Positioned(
              bottom: 8,
              right: 8,
              child: Icon(LucideIcons.qrCode, color: Colors.white.withOpacity(0.8), size: 24),
            )
          else
            Positioned(
              bottom: 8,
              left: 8,
              child: Icon(LucideIcons.user, color: Colors.white.withOpacity(0.5), size: 30),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _FeedItem(icon: LucideIcons.messageSquare, title: 'New scam number', subtitle: 'reported', time: '2h ago', color: Colors.orange),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          _FeedItem(icon: LucideIcons.mail, title: 'Fake bank SMS', subtitle: 'alert', time: '5h ago', color: Colors.redAccent),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                children: [
                  TextSpan(text: '$title ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  TextSpan(text: subtitle, style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
