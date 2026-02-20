import 'package:flutter/material.dart';
import 'dart:ui';
import '../constants/colors.dart';
import '../widgets/adaptive_button.dart';

class ReportDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> report;

  const ReportDetailsScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVerified = report['status'] == 'VERIFIED';

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'REPORT DETAILS',
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.textLight.withOpacity(0.7),
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textLight, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textLight),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Title Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    report['category'] ?? 'Scam Report',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
                if (isVerified)
                  Container(
                    margin: const EdgeInsets.only(left: 12, top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified_user_rounded, color: AppColors.accentGreen, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'VERIFIED',
                          style: TextStyle(
                            color: AppColors.accentGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 16, color: AppColors.textLight.withOpacity(0.5)),
                const SizedBox(width: 6),
                Text(
                  'Reported ${_getTimeAgo(report['createdAt'])}',
                  style: TextStyle(color: AppColors.textLight.withOpacity(0.7), fontSize: 13),
                ),
                const SizedBox(width: 12),
                Container(width: 4, height: 4, decoration: BoxDecoration(color: AppColors.textLight.withOpacity(0.3), shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    report['location'] ?? 'Petaling Jaya',
                    style: TextStyle(color: AppColors.textLight.withOpacity(0.7), fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 2. Scam Source Card
            const Text('SCAM SOURCE', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            _buildSourceCard(report),

            const SizedBox(height: 24),

            // 3. Message Content
            const Text('MESSAGE CONTENT', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF162032),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Text(
                '"${report['description'] ?? 'No content available.'}"',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 24),

             // 4. AI Risk Analysis
            Row(
              children: const [
                Icon(Icons.psychology, color: AppColors.accentGreen, size: 20),
                SizedBox(width: 8),
                Text('AI RISK ANALYSIS', style: TextStyle(color: AppColors.accentGreen, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accentGreen.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  ..._buildRiskPoints(report).asMap().entries.map((entry) {
                    return Column(
                      children: [
                        if (entry.key > 0) const SizedBox(height: 16),
                        _riskItem(entry.value['title']!, entry.value['desc']!),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 5. Actions
            AdaptiveButton(
              text: 'Stay Safe: Block This Number',
              onPressed: () {},
              icon: const Icon(Icons.block_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_rounded, size: 20),
                label: const Text('Share with Friends'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textLight,
                  side: BorderSide(color: AppColors.textLight.withOpacity(0.2)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            const SizedBox(height: 32),
            
            // 6. Screenshots (Blurred)
            Row(
              children: [
                Expanded(child: _screenshotPlaceholder()),
                const SizedBox(width: 12),
                Expanded(child: _screenshotPlaceholder()),
                const SizedBox(width: 12),
                Expanded(child: _screenshotPlaceholder()),
              ],
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Screenshots are anonymized to protect user privacy.',
                  style: TextStyle(color: AppColors.textLight.withOpacity(0.4), fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Builds the source card based on report type (Phone / Message / Document / Others)
  Widget _buildSourceCard(Map<String, dynamic> report) {
    final type = report['type'] ?? 'Message';
    final target = report['target'] as String? ?? '';

    final IconData icon;
    final String label;
    final String sublabel;

    switch (type) {
      case 'Phone':
        icon = Icons.phone_rounded;
        label = 'Call from $target';
        sublabel = 'Malaysia Mobile Network';
        break;
      case 'Document':
        icon = Icons.description_rounded;
        label = 'Document: ${target.isNotEmpty ? target : "Attached file"}';
        sublabel = 'Uploaded evidence file';
        break;
      case 'Message':
        icon = Icons.sms_rounded;
        label = target.isNotEmpty ? 'SMS from $target' : 'Suspicious message';
        sublabel = 'Malaysia Mobile Network';
        break;
      default:
        icon = Icons.warning_amber_rounded;
        label = target.isNotEmpty ? target : 'Other scam source';
        sublabel = 'Reported by community';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF162032),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF3B82F6), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  sublabel,
                  style: TextStyle(color: AppColors.textLight.withOpacity(0.5), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Generates dynamic AI risk analysis bullets from report fields
  List<Map<String, String>> _buildRiskPoints(Map<String, dynamic> report) {
    final points = <Map<String, String>>[];
    final category = (report['category'] ?? '').toString().toLowerCase();
    final type = (report['type'] ?? '').toString();
    final count = (report['_count']?['verifications'] ?? 0) as int;
    final description = (report['description'] ?? '').toString().toLowerCase();

    // Category-level signal
    if (category.contains('phishing') || category.contains('wallet')) {
      points.add({
        'title': 'Sense of Urgency',
        'desc': 'Phishing messages often claim accounts are suspended to pressure victims into acting fast.',
      });
      if (description.contains('link') || description.contains('url') || description.contains('bit.ly')) {
        points.add({
          'title': 'Suspicious Link',
          'desc': 'URL shortener or unofficial domain used to mask a phishing site.',
        });
      }
    } else if (category.contains('investment')) {
      points.add({
        'title': 'Unrealistic Returns',
        'desc': '"Guaranteed" high-return schemes are always red flags. Check BNM Alert List before investing.',
      });
      if (description.contains('telegram') || description.contains('whatsapp') || description.contains('group')) {
        points.add({
          'title': 'Social Media Pressure',
          'desc': 'Scammers often use closed group chats to fabricate testimonials and urgency.',
        });
      }
    } else if (category.contains('courier') || category.contains('delivery')) {
      points.add({
        'title': 'Impersonation Tactic',
        'desc': 'Official couriers never request bank details or fees via phone call.',
      });
      points.add({
        'title': 'Illegal Parcel Threat',
        'desc': 'Threatening legal action over a parcel is a known social engineering tactic.',
      });
    } else if (category.contains('love') || category.contains('romance')) {
      points.add({
        'title': 'Emotional Manipulation',
        'desc': 'Romance scammers build trust over time before making financial requests.',
      });
    } else if (category.contains('job')) {
      points.add({
        'title': 'Advance Fee',
        'desc': 'Legitimate employers never ask you to pay upfront to secure a job offer.',
      });
    }

    // Source type signal
    if (type == 'Phone') {
      points.add({
        'title': 'Sender ID',
        'desc': 'Unknown mobile number used instead of an official registered shortcode.',
      });
    }

    // Community verification signal
    if (count > 3) {
      points.add({
        'title': 'Community Flagged',
        'desc': '$count users have independently reported this as a scam — treat with high caution.',
      });
    }

    // Fallback
    if (points.isEmpty) {
      points.add({
        'title': 'Unverified Source',
        'desc': 'Always verify the source before taking any action on unsolicited messages.',
      });
    }

    return points;
  }

  Widget _riskItem(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFF87171), // Red
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(height: 1.5, fontSize: 14),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: desc,
                  style: TextStyle(color: AppColors.textLight.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _screenshotPlaceholder() {
    return AspectRatio(
      aspectRatio: 3/4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
           borderRadius: BorderRadius.circular(12),
           child: Stack(
             fit: StackFit.expand,
             children: [
               // Mock Content
               Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.image, color: Colors.white.withOpacity(0.2), size: 32),
                 ],
               ),
               // Blur it
               BackdropFilter(
                 filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                 child: Container(color: Colors.black.withOpacity(0.1)),
               ),
               Center(
                 child: Icon(Icons.visibility_off, color: Colors.white.withOpacity(0.5), size: 24),
               ),
             ],
           ),
        ),
      ),
    );
  }

  String _getTimeAgo(String? dateStr) {
    if (dateStr == null) return '2 hours ago';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (_) {
      return '2 hours ago';
    }
  }
}
