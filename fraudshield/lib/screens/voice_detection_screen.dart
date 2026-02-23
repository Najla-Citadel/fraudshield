import 'dart:async';
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

class _VoiceDetectionScreenState extends State<VoiceDetectionScreen> with SingleTickerProviderStateMixin {
  bool isRecording = false;
  bool isAnalyzing = false;
  bool? isSuspicious; // null = no result yet
  int _recordingDurationSeconds = 0;
  Timer? _timer;
  
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
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      isRecording = true;
      isAnalyzing = false;
      isSuspicious = null;
      _recordingDurationSeconds = 0;
    });
    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDurationSeconds++;
      });
    });
  }

  void _stopRecording() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      isRecording = false;
      isAnalyzing = true;
    });
    
    // Simulate AI analysis delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Randomly determine result for demo purposes
    final bool isBad = DateTime.now().second % 2 == 0;
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')} ${_getMonth(now.month)} ${now.year}';
    final nameStr = 'Voice_${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}_${now.hour.toString().padLeft(2,'0')}${now.minute.toString().padLeft(2,'0')}';
    
    if (mounted) {
      setState(() {
        isAnalyzing = false;
        isSuspicious = isBad;
        // Add to recent recordings
        recentRecordings.insert(0, {
          'name': nameStr,
          'result': isBad ? 'Suspicious' : 'Safe',
          'date': dateStr,
        });
      });
    }
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _toggleRecording() {
    if (isRecording) {
      _stopRecording();
    } else if (!isAnalyzing) {
      _startRecording();
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds / 60).floor().toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Voice Detection',
      backgroundColor: AppColors.deepNavy,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // 🗣 Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.mic_none_outlined, color: AppColors.primaryBlue, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice Analysis',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Identify scam calls in real-time.',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),

            // 🎙 Record Button
            GestureDetector(
              onTap: _toggleRecording,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final scale = isRecording ? _pulseAnimation.value : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isRecording 
                              ? [Colors.redAccent.shade400, Colors.red.shade700]
                              : [AppColors.primaryBlue, AppColors.primaryBlue.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isRecording ? Colors.red : AppColors.primaryBlue).withOpacity(0.4),
                            blurRadius: isRecording ? 24 : 16,
                            spreadRadius: isRecording ? 8 : 4,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                      child: isAnalyzing
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 3,
                              ),
                            )
                          : Icon(
                              isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                              color: Colors.white,
                              size: 64,
                            ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // ⏱ Status Text
            if (isAnalyzing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                   color: AppColors.primaryBlue.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(20),
                   border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Analyzing AI Voice Signatures...',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else if (isRecording)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                           width: 8, height: 8,
                           decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Listening...',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatDuration(_recordingDurationSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 42,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              )
            else
              Text(
                'Tap mic to start scanning',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),

            const SizedBox(height: 48),

            // 🟢 Result Section
            if (isSuspicious != null && !isRecording && !isAnalyzing)
              AnimationConfiguration.synchronized(
                child: FadeInAnimation(
                  duration: const Duration(milliseconds: 500),
                  child: SlideAnimation(
                    verticalOffset: 20,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isSuspicious! ? Colors.red.withOpacity(0.08) : Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSuspicious! ? Colors.redAccent.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSuspicious! ? Colors.redAccent.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSuspicious! ? Icons.gpp_bad_rounded : Icons.gpp_good_rounded,
                              color: isSuspicious! ? Colors.redAccent : Colors.green,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isSuspicious! ? 'High Risk Detected' : 'Voice is Safe',
                            style: TextStyle(
                              color: isSuspicious! ? Colors.redAccent : Colors.green,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isSuspicious!
                                ? 'AI analysis indicates a high probability of a scam attempt or deepfake voice. Do not share sensitive information.'
                                : 'Analysis complete. No suspicious voice patterns or known scammer signatures detected.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              height: 1.5,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            if (isSuspicious != null) const SizedBox(height: 40),

            // 🧾 Recent Recordings
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                 color: const Color(0xFF1E293B),
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: AnimationLimiter(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentRecordings.length,
                  separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
                  itemBuilder: (context, index) {
                    final item = recentRecordings[index];
                    final isBad = item['result'] == 'Suspicious';
                    
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 30.0,
                        child: FadeInAnimation(
                          child: InkWell(
                            onTap: () {},
                            borderRadius: index == 0 ? const BorderRadius.vertical(top: Radius.circular(20)) 
                                        : index == recentRecordings.length - 1 ? const BorderRadius.vertical(bottom: Radius.circular(20))
                                        : BorderRadius.zero,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isBad ? Colors.redAccent.withOpacity(0.15) : AppColors.accentGreen.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isBad ? Icons.warning_amber_rounded : Icons.check_circle,
                                      color: isBad ? Colors.redAccent : AppColors.accentGreen,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['date'],
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white.withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isBad ? Colors.redAccent.withOpacity(0.15) : AppColors.accentGreen.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                         color: isBad ? Colors.redAccent.withOpacity(0.3) : AppColors.accentGreen.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      item['result'],
                                      style: TextStyle(
                                        color: isBad ? Colors.redAccent : AppColors.accentGreen,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
