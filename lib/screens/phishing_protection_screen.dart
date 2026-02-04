// lib/screens/phishing_protection_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/core/primary_button.dart';
import '../widgets/core/section_header.dart';
import '../widgets/core/status_badge.dart';

class PhishingProtectionScreen extends StatefulWidget {
  const PhishingProtectionScreen({super.key});

  @override
  State<PhishingProtectionScreen> createState() => _PhishingProtectionScreenState();
}

class _PhishingProtectionScreenState extends State<PhishingProtectionScreen> {
  bool isProtected = true;

  final List<Map<String, dynamic>> recentActivities = [
    {'url': 'www.bank-secure-update.com', 'status': 'Suspicious', 'date': '03 Nov 2025'},
    {'url': 'www.maybank2u.com.my', 'status': 'Safe', 'date': '02 Nov 2025'},
    {'url': 'sms: +60123456789', 'status': 'Suspicious', 'date': '01 Nov 2025'},
    {'url': 'www.lazada.com.my', 'status': 'Safe', 'date': '30 Oct 2025'},
  ];

  @override
  Widget build(BuildContext context) {
    final statusColor = isProtected ? AppColors.success : AppColors.error;
    final statusIcon = isProtected ? Icons.gpp_good : Icons.gpp_bad;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Phishing Protection')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            // 🛡️ STATUS CARD
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(color: statusColor.withOpacity(0.2), width: 2),
              ),
              child: Column(
                children: [
                  Icon(statusIcon, size: 80, color: statusColor),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    isProtected ? 'You are Protected' : 'Protection Disabled',
                    style: AppTypography.h2.copyWith(color: statusColor),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    isProtected 
                        ? 'Real-time scanning is active.' 
                        : 'Enable scanning to stay safe.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyM,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  
                  PrimaryButton(
                    label: isProtected ? 'Simulate Threat' : 'Enable Protection',
                    onPressed: () => setState(() => isProtected = !isProtected),
                    isFullWidth: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // 📋 RECENT ACTIVITY
            const SectionHeader(title: 'Recent Scans', actionLabel: ''),
            const SizedBox(height: AppSpacing.s),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentActivities.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
              itemBuilder: (ctx, i) {
                final item = recentActivities[i];
                final isSuspicious = item['status'] == 'Suspicious';
                
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusS),
                        ),
                        child: Icon(
                          isSuspicious ? Icons.link_off : Icons.link,
                          color: isSuspicious ? AppColors.error : AppColors.success,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['url'], 
                              style: AppTypography.bodyL.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(item['date'], style: AppTypography.bodyS),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: item['status'],
                        status: isSuspicious ? BadgeStatus.danger : BadgeStatus.safe,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
