// lib/screens/voice_detection_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/core/primary_button.dart';
import '../widgets/core/section_header.dart';
import '../widgets/core/status_badge.dart';

class VoiceDetectionScreen extends StatefulWidget {
  const VoiceDetectionScreen({super.key});

  @override
  State<VoiceDetectionScreen> createState() => _VoiceDetectionScreenState();
}

class _VoiceDetectionScreenState extends State<VoiceDetectionScreen> with SingleTickerProviderStateMixin {
  bool isRecording = false;
  bool? isSuspicious;

  // Animation for the "listening" effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> recentRecordings = [
    {'name': 'Call_20251101_1805', 'result': 'Safe', 'date': '01 Nov 2025'},
    {'name': 'Call_20251029_1420', 'result': 'Suspicious', 'date': '29 Oct 2025'},
    {'name': 'Voice_20251025_1032', 'result': 'Safe', 'date': '25 Oct 2025'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    setState(() {
      if (isRecording) {
        // Stop
        isRecording = false;
        // Mock analysis
        isSuspicious = DateTime.now().second % 2 == 0;
      } else {
        // Start
        isRecording = true;
        isSuspicious = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Voice Detection')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            // 🎙️ RECORDING AREA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                 boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    isRecording ? 'Listening...' : 'Tap to Analyze',
                    style: AppTypography.h2,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'AI will analyze current audio for scam patterns.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyM,
                    ),
                  ),
                  
                  const SizedBox(height: 40),

                  GestureDetector(
                    onTap: _toggleRecording,
                    child: ScaleTransition(
                      scale: isRecording ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRecording ? AppColors.error : AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: (isRecording ? AppColors.error : AppColors.primary).withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          isRecording ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // 🟢 RESULT
            if (isSuspicious != null)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.l),
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: isSuspicious! ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                  border: Border.all(color: isSuspicious! ? AppColors.error : AppColors.success),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSuspicious! ? Icons.warning_amber : Icons.check_circle,
                      color: isSuspicious! ? AppColors.error : AppColors.success,
                      size: 32,
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSuspicious! ? 'Suspicious Voice Detected' : 'Voice Appears Safe',
                            style: AppTypography.h3.copyWith(fontSize: 16),
                          ),
                          Text(
                            isSuspicious! ? 'Pattern matches known scam scripts.' : 'No scam patterns found.',
                            style: AppTypography.bodyS,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),

             const SectionHeader(title: 'Recent Analysis', actionLabel: ''),
             const SizedBox(height: AppSpacing.s),

             // HISTORY
             ListView.separated(
               shrinkWrap: true,
               physics: const NeverScrollableScrollPhysics(),
               itemCount: recentRecordings.length,
               separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
               itemBuilder: (ctx, i) {
                 final item = recentRecordings[i];
                 final isSus = item['result'] == 'Suspicious';
                 return Container(
                   padding: const EdgeInsets.all(AppSpacing.m),
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(AppSpacing.radiusS),
                   ),
                   child: Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(
                           color: AppColors.backgroundLight,
                           shape: BoxShape.circle,
                         ),
                         child: const Icon(Icons.history_edu, size: 20, color: AppColors.textSecondary),
                       ),
                       const SizedBox(width: AppSpacing.m),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(item['name'], style: AppTypography.bodyL.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                             Text(item['date'], style: AppTypography.bodyS),
                           ],
                         ),
                       ),
                       StatusBadge(
                         label: item['result'], 
                         status: isSus ? BadgeStatus.danger : BadgeStatus.safe
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
