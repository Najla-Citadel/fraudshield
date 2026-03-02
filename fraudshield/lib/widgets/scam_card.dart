import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/colors.dart';
import '../screens/report_details_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui'; // For ImageFilter if needed
class ScamCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onVerify;
  final VoidCallback? onTap;

  const ScamCard({
    super.key,
    required this.report,
    required this.onVerify,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use status field from report data (VERIFIED / PENDING)
    final isVerified = report['status'] == 'VERIFIED';
    final verificationCount = (report['_count']?['verifications'] ?? 0) as int;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header: Icon + Title + Badge ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(report['category']).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(report['category']),
                    color: _getCategoryColor(report['category']),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Title & Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              report['category'] ?? 'Scam Report',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Badge
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isVerified 
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15) 
                                  : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20), // Pill shape
                              border: Border.all(
                                color: isVerified 
                                    ? const Color(0xFF10B981).withValues(alpha: 0.5)
                                    : const Color(0xFFF59E0B).withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isVerified ? LucideIcons.checkCircle2 : LucideIcons.clock,
                                  size: 12,
                                  color: isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isVerified ? 'VERIFIED' : 'PENDING',
                                  style: TextStyle(
                                    color: isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getTimeAgo(report['createdAt'])} • ${report['user'] ?? 'Anonymous'}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- Location (Mocked for now if not in API) ---
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report['target'] ?? report['description']?.toString().split('\n').first ?? 'General Threat',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // --- "Stay Safe" Blue Box ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), // Very light blue
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)), // Soft blue border
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 14, color: Color(0xFF2563EB)),
                            SizedBox(width: 6),
                            Text(
                              'Stay Safe:',
                              style: TextStyle(
                                color: Color(0xFF1E3A8A),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStaySafeTip(report['category']),
                          style: const TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- Footer: Avatars + Action ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Avatar Pile & Count
                if (verificationCount > 0)
                  Row(
                    children: [
                      _buildAvatarPile(verificationCount),
                      const SizedBox(width: 8),
                      Text(
                        '$verificationCount ${verificationCount == 1 ? "person" : "people"} flagged this',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Be the first to flag this',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                // Alert Action Button
                InkWell(
                  onTap: () {
                     // TODO: Implement alert sharing
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9), // Slate 100
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(LucideIcons.share2, size: 14, color: AppColors.primaryBlue),
                        SizedBox(width: 6),
                        Text(
                          'Share Alert',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }

  // --- Helper Methods ---

  Widget _buildAvatarPile(int count) {
    final label = count > 2 ? '+${count - 2}' : null;
    return SizedBox(
      width: 60,
      height: 24,
      child: Stack(
        children: [
          _buildAvatar(0, Colors.teal[200]!),
          Positioned(left: 14, child: _buildAvatar(1, Colors.orange[200]!)),
          Positioned(left: 28, child: _buildAvatar(2, Colors.grey[700]!, text: label)),
        ],
      ),
    );
  }

  Widget _buildAvatar(int index, Color color, {String? text}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2), // White border for pile
      ),
      child: Center(
        child: text != null 
            ? Text(text, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white))
            : const Icon(Icons.person, size: 14, color: Colors.white), // Using white icon on colorful bg
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    if (category?.toLowerCase().contains('phishing') == true) return const Color(0xFFF87171); // Red
    if (category?.toLowerCase().contains('investment') == true) return const Color(0xFFFBBF24); // Amber
    if (category?.toLowerCase().contains('courier') == true) return const Color(0xFF60A5FA); // Blue
    return Colors.purpleAccent;
  }

  IconData _getCategoryIcon(String? category) {
    if (category?.toLowerCase().contains('phishing') == true) return Icons.account_balance_wallet_outlined;
    if (category?.toLowerCase().contains('investment') == true) return Icons.trending_up_rounded;
    if (category?.toLowerCase().contains('courier') == true) return Icons.local_shipping_outlined;
    return Icons.warning_amber_rounded;
  }

  String _getStaySafeTip(String? category) {
    if (category?.toLowerCase().contains('phishing') == true) {
      return 'Avoid clicking links in SMS claiming "Account Verification". Real providers never ask for PIN via SMS.';
    }
    if (category?.toLowerCase().contains('investment') == true) {
      return '"Guaranteed 200% returns" are always red flags. Check BNM Alert List before investing.';
    }
    if (category?.toLowerCase().contains('courier') == true) {
      return 'Do not pay "unpaid taxes" for packages via WhatsApp links. Verify with official courier apps.';
    }
    return 'Always verify the source before taking any action. If it sounds too good to be true, it probably is.';
  }

  String _getTimeAgo(String? dateStr) {
    if (dateStr == null) return 'Just now';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (_) {
      return 'Just now';
    }
  }

}
