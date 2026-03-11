import 'package:flutter/material.dart';
import '../design_system/tokens/design_tokens.dart';
import 'package:lucide_icons/lucide_icons.dart';
// For ImageFilter if needed

class ScamCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onVerify;
  final VoidCallback? onTap;
  final void Function(String targetId, String type)? onFlag;

  const ScamCard({
    super.key,
    required this.report,
    required this.onVerify,
    this.onTap,
    this.onFlag,
  });

  @override
  Widget build(BuildContext context) {
    // Use status field from report data (VERIFIED / PENDING)
    final isVerified = report['status'] == 'VERIFIED';
    final verificationCount = (report['_count']?['verifications'] ?? 0) as int;
    final source = report['source'] ?? 'community';
    final isOfficial = source == 'official' || source == 'law_enforcement';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: DesignTokens.spacing.xl, left: DesignTokens.spacing.lg, right: DesignTokens.spacing.lg),
        decoration: BoxDecoration(
          color: isOfficial ? Color(0xFF0F2942) : Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(DesignTokens.radii.xl),
          border: Border.all(
            color: isOfficial ? Color(0xFF3B82F6).withOpacity(0.4) : Colors.white.withOpacity(0.1),
            width: isOfficial ? 1.5 : 1,
          ),
          boxShadow: DesignTokens.shadows.md,
        ),
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacing.lg),
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
                      color: isOfficial
                          ? Color(0xFF3B82F6).withOpacity(0.2)
                          : _getCategoryColor(report['category'])
                              .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
                    ),
                    child: Icon(
                      isOfficial ? LucideIcons.shieldCheck : _getCategoryIcon(report['category']),
                      color: isOfficial ? Color(0xFF3B82F6) : _getCategoryColor(report['category']),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),

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
                              margin: EdgeInsets.only(left: DesignTokens.spacing.sm),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isVerified
                                    ? Color(0xFF10B981)
                                        .withOpacity(0.15)
                                    : Color(0xFFF59E0B)
                                        .withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(DesignTokens.radii.lg), // Pill shape
                                border: Border.all(
                                  color: isVerified
                                      ? Color(0xFF10B981)
                                          .withOpacity(0.5)
                                      : Color(0xFFF59E0B)
                                          .withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isVerified
                                        ? LucideIcons.checkCircle2
                                        : LucideIcons.clock,
                                    size: 12,
                                    color: isVerified
                                        ? Color(0xFF10B981)
                                        : Color(0xFFF59E0B),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    isVerified ? 'VERIFIED' : 'PENDING',
                                    style: TextStyle(
                                      color: isVerified
                                          ? Color(0xFF10B981)
                                          : Color(0xFFF59E0B),
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
                        SizedBox(height: 4),
                        Text(
                          '${_getTimeAgo(report['createdAt'])} • ${isOfficial ? (source == 'law_enforcement' ? 'Law Enforcement' : 'Official Advisory') : 'Community Member'}',
                          style: TextStyle(
                            color: isOfficial ? Color(0xFF60A5FA) : Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: isOfficial ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // --- Location (Mocked for now if not in API) ---
              Row(
                children: [
                  Icon(LucideIcons.mapPin,
                      size: 16, color: Colors.white.withOpacity(0.5)),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report['target'] ??
                          report['description']?.toString().split('\n').first ??
                          'General Threat',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // --- "Stay Safe" Blue Box ---
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(DesignTokens.spacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(DesignTokens.radii.md),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 3,
                      height: 40,
                      decoration: BoxDecoration(
                        color: DesignTokens.colors.accentGreen,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.shield,
                                  size: 14, color: DesignTokens.colors.accentGreen),
                              SizedBox(width: 6),
                              Text(
                                'Stay Safe:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
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

              SizedBox(height: 16),

              // --- Footer: Avatars + Action ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Avatar Pile & Count
                  if (verificationCount > 0)
                    Row(
                      children: [
                        _buildAvatarPile(verificationCount),
                        SizedBox(width: 8),
                        Text(
                          '$verificationCount ${verificationCount == 1 ? "person" : "people"} flagged this',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Be the first to flag this',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                  // Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Flag Button
                      if (onFlag != null)
                        InkWell(
                          onTap: () => onFlag!(report['id'] ?? '', 'report'),
                          borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
                          child: Container(
                            padding: EdgeInsets.all(DesignTokens.spacing.sm),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
                            ),
                            child: Icon(LucideIcons.flag,
                                size: 14, color: Colors.white.withOpacity(0.6)),
                          ),
                        ),
                      if (onFlag != null) SizedBox(width: 8),
                      // Share Alert Button
                      InkWell(
                        onTap: () {
                          // TODO: Implement alert sharing
                        },
                        borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: DesignTokens.spacing.md, vertical: DesignTokens.spacing.sm),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.share2,
                                  size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Share Alert',
                                style: TextStyle(
                                  color: Colors.white,
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
          Positioned(
              left: 28, child: _buildAvatar(2, Colors.grey[700]!, text: label)),
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
        border: Border.all(
            color: Color(0xFF1E293B),
            width: 2), // Slate 800 border instead of white
      ),
      child: Center(
        child: text != null
            ? Text(text,
                style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white))
            : const Icon(LucideIcons.user,
                size: 14,
                color: Colors.white), // Using white icon on colorful bg
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    if (category?.toLowerCase().contains('phishing') == true) {
      return Color(0xFFF87171); // Red
    }
    if (category?.toLowerCase().contains('investment') == true) {
      return Color(0xFFFBBF24); // Amber
    }
    if (category?.toLowerCase().contains('courier') == true) {
      return Color(0xFF60A5FA); // Blue
    }
    return Colors.purpleAccent;
  }

  IconData _getCategoryIcon(String? category) {
    if (category?.toLowerCase().contains('phishing') == true) {
      return LucideIcons.wallet;
    }
    if (category?.toLowerCase().contains('investment') == true) {
      return LucideIcons.trendingUp;
    }
    if (category?.toLowerCase().contains('courier') == true) {
      return LucideIcons.truck;
    }
    return LucideIcons.alertTriangle;
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
