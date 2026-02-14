import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/colors.dart';
import '../screens/report_details_screen.dart';
// import 'glass_card.dart'; // No longer using generic GlassCard to have more control over specific design

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
    // Mock logic for demo verification status
    final isVerified = (report['category'] == 'E-Wallet Phishing' || report['category'] == 'Courier Impersonation'); 
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark Slate
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    color: _getCategoryColor(report['category']).withOpacity(0.2),
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
                                color: Colors.white,
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isVerified 
                                  ? const Color(0xFF10B981).withOpacity(0.2) 
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isVerified 
                                    ? const Color(0xFF10B981).withOpacity(0.5)
                                    : Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              isVerified ? 'VERIFIED' : 'PENDING',
                              style: TextStyle(
                                color: isVerified ? const Color(0xFF10B981) : Colors.white.withOpacity(0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getTimeAgo(report['createdAt'])} • ${report['user'] ?? 'User${report['id'].toString().substring(0, 4)}xx'}', // Mock user ID pattern
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
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
                Icon(Icons.location_on, size: 16, color: Colors.white.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text(
                  report['location'] ?? 'Kuala Lumpur, Malaysia', // Fallback location
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- "Stay Safe" Blue Box ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF172554).withOpacity(0.5), // Deep Blue tint
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)), // Blue border
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1E3A8A).withOpacity(0.4),
                    const Color(0xFF1E293B).withOpacity(0.1),
                  ],
                ),
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
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF60A5FA)),
                            const SizedBox(width: 6),
                            const Text(
                              'Stay Safe:',
                              style: TextStyle(
                                color: Color(0xFF60A5FA),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStaySafeTip(report['category']),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
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

            const SizedBox(height: 20),

            // --- Footer: Avatars + Action ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Avatar Pile (Mock)
                Row(
                  children: [
                    _buildAvatarPile(),
                    const SizedBox(width: 8),
                    if (report['category'] == 'Investment Scam')
                      Container( // ! 8 people flagged this
                        padding: const EdgeInsets.only(left: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.priority_high_rounded, color: Colors.redAccent, size: 14),
                            Text(
                              ' 8 people flagged this',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Alert Action
                InkWell(
                  onTap: () {
                     // TODO: Implement alert sharing
                  },
                  child: Row(
                    children: [
                      Icon(Icons.ios_share_rounded, size: 16, color: Colors.white.withOpacity(0.7)),
                      const SizedBox(width: 6),
                      Text(
                        'Alert Others',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

  Widget _buildAvatarPile() {
    // Just static colored circles for now
    return SizedBox(
      width: 60,
      height: 24,
      child: Stack(
        children: [
          _buildAvatar(0, Colors.teal[200]!),
          Positioned(left: 14, child: _buildAvatar(1, Colors.orange[200]!)),
          Positioned(left: 28, child: _buildAvatar(2, Colors.grey[700]!, text: '+12')),
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
        border: Border.all(color: const Color(0xFF1E293B), width: 2),
      ),
      child: Center(
        child: text != null 
            ? Text(text, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white))
            : const Icon(Icons.person, size: 14, color: Colors.black54),
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

  // NOTE: Kept original logic for reference but unused in new UI to match design strictly
  Color _getTrustColor(num score) {
    if (score >= 50) return Colors.purpleAccent;
    if (score >= 20) return Colors.lightBlueAccent;
    if (score > 0) return AppColors.accentGreen;
    return Colors.grey;
  }
}
