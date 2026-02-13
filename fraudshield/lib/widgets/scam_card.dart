import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/colors.dart';
import '../screens/report_details_screen.dart';
import 'glass_card.dart';

class ScamCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onVerify;

  const ScamCard({
    super.key,
    required this.report,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final theme = Theme.of(context);
      
      // Safe extraction of verification count
      num verifications = 0;
      if (report.containsKey('_count') && report['_count'] is Map) {
        verifications = report['_count']['verifications'] ?? 0;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GlassCard(
          padding: EdgeInsets.zero, // InkWell needs to span full width
          child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportDetailsScreen(
                  reportId: report['id'],
                  initialData: report,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (report['category'] ?? 'SCAM').toString().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatDate(report['createdAt']),
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 12,
                              color: _getTrustColor((report['reporterTrust']?['score'] as num?)?.toInt() ?? 0),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Trust: ${report['reporterTrust']?['score'] ?? 0}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _getTrustColor((report['reporterTrust']?['score'] as num?)?.toInt() ?? 0),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                if (report['reporterTrust'] != null) ...[
                  () {
                    List badges = [];
                    final rawBadges = report['reporterTrust']['badges'];
                    if (rawBadges is List) {
                      badges = rawBadges;
                    } else if (rawBadges is String && rawBadges.isNotEmpty) {
                      try {
                        final decoded = jsonDecode(rawBadges);
                        if (decoded is List) {
                          badges = decoded;
                        }
                      } catch (e) {
                        debugPrint('Error decoding badges: $e');
                      }
                    }
                    
                    if (badges.isEmpty) return const SizedBox.shrink();
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: badges.map((badge) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.amber.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.stars, size: 10, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    badge.toString(),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  }(),
                ],
                const SizedBox(height: 12),
                Text(
                  report['description'] ?? 'No description provided',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                if (report['target'] != null && report['target'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.link, size: 14, color: Colors.blueAccent),
                        const SizedBox(width: 6),
                        Text(
                          report['target'].toString(),
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.1)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 16, color: Colors.white.withOpacity(0.5)),
                        const SizedBox(width: 6),
                        Text(
                          '$verifications matched',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => _handleVerify(context),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('I saw this'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ));
    } catch (e, stack) {
      debugPrint('Error rendering ScamCard for report ${report['id']}: $e\n$stack');
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GlassCard(
          child: ListTile(
            leading: const Icon(Icons.error_outline, color: Colors.red),
            title: const Text('Invalid report data'),
            subtitle: Text('Details: ${e.toString().split('\n').first}'),
          ),
        ),
      );
    }
  }

  Future<void> _handleVerify(BuildContext context) async {
    try {
      await ApiService.instance.verifyReport(
        reportId: report['id'],
        isSame: true,
      );
      onVerify();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you! Helping the community stay safe.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to verify: $e')),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Invalid date';
    }
  }

  Color _getTrustColor(num score) {
    if (score >= 50) return Colors.purpleAccent; // Lighter purple
    if (score >= 20) return Colors.lightBlueAccent; // Lighter blue
    if (score > 0) return AppColors.accentGreen; // Vibrant green
    return Colors.grey;
  }
}
