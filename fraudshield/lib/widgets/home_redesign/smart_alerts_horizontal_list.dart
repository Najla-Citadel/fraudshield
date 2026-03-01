import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/colors.dart';

class SmartAlertsHorizontalList extends StatelessWidget {
  final bool isSubscribed;
  final VoidCallback onMessageScan;
  final VoidCallback onPdfScan;
  final VoidCallback onApkScan;
  final VoidCallback onVoiceDetection;

  const SmartAlertsHorizontalList({
    super.key,
    required this.isSubscribed,
    required this.onMessageScan,
    required this.onPdfScan,
    required this.onApkScan,
    required this.onVoiceDetection,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.only(right: 16), // Adds padding at the end of the scroll to let the last item peek
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
          _SmartAlertCard(
            icon: LucideIcons.messageSquare,
            label: 'SMS Analysis',
            isSubscribed: isSubscribed,
            onTap: onMessageScan,
          ),
          const SizedBox(width: 12),
          _SmartAlertCard(
            icon: LucideIcons.phoneCall,
            label: 'Call Screening',
            isSubscribed: isSubscribed,
            onTap: onVoiceDetection,
          ),
          const SizedBox(width: 12),
          _SmartAlertCard(
            icon: LucideIcons.fileText,
            label: 'File Security',
            isSubscribed: isSubscribed,
            onTap: onPdfScan,
          ),
        ],
      ),
    );
  }
}

class _SmartAlertCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSubscribed;
  final VoidCallback onTap;

  const _SmartAlertCard({
    required this.icon,
    required this.label,
    required this.isSubscribed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 110, // Fixed width based on screenshot
        height: 70, 
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFF9E6), // Very light premium gold
              const Color(0xFFFFF2CC), // Slightly deeper premium gold
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, // Align left
                children: [
                   Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: const Color(0xFF8B6B15), size: 20), // Dark gold icon
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                                // PRO gold badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.premiumYellow,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PRO',
                                    style: TextStyle(
                                      color: Colors.black, // AppColors.textDark
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (!isSubscribed) ...[
                                  const SizedBox(height: 4),
                                  const Icon(
                                    Icons.lock_outline,
                                    color: AppColors.premiumYellow,
                                    size: 12,
                                  ),
                                ]
                            ]
                        )
                      ],
                  ),
                  const Spacer(),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textDark, 
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
