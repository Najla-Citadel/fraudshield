import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/glass_card.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class VoiceDetectionScreen extends StatefulWidget {
  const VoiceDetectionScreen({super.key});

  @override
  State<VoiceDetectionScreen> createState() => _VoiceDetectionScreenState();
}

class _VoiceDetectionScreenState extends State<VoiceDetectionScreen> {
  bool isRecording = false;
  bool? isSuspicious; // null = no result yet

  final List<Map<String, dynamic>> recentRecordings = [
    {'name': 'Call_20251101_1805', 'result': 'Safe', 'date': '01 Nov 2025'},
    {'name': 'Call_20251029_1420', 'result': 'Suspicious', 'date': '29 Oct 2025'},
    {'name': 'Voice_20251025_1032', 'result': 'Safe', 'date': '25 Oct 2025'},
  ];

  void _toggleRecording() {
    setState(() {
      if (isRecording) {
        // Stop and analyze
        isRecording = false;
        // Mock random detection
        isSuspicious = DateTime.now().second % 2 == 0;
      } else {
        // Start recording
        isRecording = true;
        isSuspicious = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Voice Detection',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // 🗣️ Header
            Text(
              'Identify scam calls or suspicious voice patterns.',
              style: TextStyle(
                color: AppColors.darkText,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // 🎙️ Record Button
            GestureDetector(
              onTap: _toggleRecording,
              child: Hero(
                tag: 'hero_voice',
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isRecording ? Colors.redAccent : AppColors.primaryBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isRecording
                                ? Colors.redAccent
                                : AppColors.primaryBlue)
                            .withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              isRecording
                  ? 'Listening... Tap to stop'
                  : 'Tap to start recording',
              style: TextStyle(
                color: AppColors.greyText,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 40),

            // 🟢 Result Section
            if (isSuspicious != null)
              GlassCard(
                accentColor: isSuspicious! ? Colors.redAccent : Colors.green,
                child: Column(
                  children: [
                    Icon(
                      isSuspicious!
                          ? Icons.warning_amber_rounded
                          : Icons.verified_user,
                      color: isSuspicious!
                          ? Colors.redAccent
                          : Colors.green,
                      size: 70,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isSuspicious!
                          ? 'Suspicious Voice Detected!'
                          : 'Voice is Safe',
                      style: TextStyle(
                        color: isSuspicious!
                            ? Colors.redAccent
                            : Colors.green[800],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isSuspicious!
                          ? 'Potential scam or fake voice identified.'
                          : 'No suspicious tone detected.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.greyText),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),

            // 🧾 Recent Recordings
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Recordings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
            ),
            const SizedBox(height: 12),

            GlassCard(
              padding: EdgeInsets.zero,
              child: AnimationLimiter(
                child: Column(
                  children: recentRecordings.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSuspicious = item['result'] == 'Suspicious';
                    
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: ListTile(
                            leading: Icon(
                              isSuspicious
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle,
                              color: isSuspicious
                                  ? Colors.redAccent
                                  : Colors.green,
                            ),
                            title: Text(
                              item['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkText,
                              ),
                            ),
                            subtitle: Text(item['date']),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSuspicious
                                    ? Colors.redAccent
                                    : Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item['result'],
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
