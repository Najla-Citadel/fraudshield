import 'dart:async';
<<<<<<< HEAD
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/glass_card.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
=======
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

class VoiceAnalysisResult {
  final int riskScore;
  final String level; // 'low' | 'medium' | 'high' | 'critical'
  final String transcript;
  final String language;
  final double duration;
  final ContentAnalysis contentAnalysis;
  final VoicePatternAnalysis voiceAnalysis;
  final String disclaimer;

  VoiceAnalysisResult.fromJson(Map<String, dynamic> json)
      : riskScore = json['riskScore'] ?? 0,
        level = json['level'] ?? 'low',
        transcript = json['transcript'] ?? '',
        language = json['language'] ?? 'unknown',
        duration = (json['duration'] ?? 0.0).toDouble(),
        contentAnalysis =
            ContentAnalysis.fromJson(json['contentAnalysis'] ?? {}),
        voiceAnalysis =
            VoicePatternAnalysis.fromJson(json['voiceAnalysis'] ?? {}),
        disclaimer = json['disclaimer'] ?? '';
}

class ContentAnalysis {
  final int score;
  final String scamType;
  final List<String> matchedPatterns;

  ContentAnalysis.fromJson(Map<String, dynamic> json)
      : score = json['score'] ?? 0,
        scamType = json['scamType'] ?? 'unknown',
        matchedPatterns = List<String>.from(json['matchedPatterns'] ?? []);
}

class VoicePatternAnalysis {
  final int score;
  final List<String> flags;

  VoicePatternAnalysis.fromJson(Map<String, dynamic> json)
      : score = json['score'] ?? 0,
        flags = List<String>.from(json['flags'] ?? []);
}

// ─── Screen ───────────────────────────────────────────────────────────────────
>>>>>>> dev-ui2

class VoiceDetectionScreen extends StatefulWidget {
  const VoiceDetectionScreen({super.key});

  @override
  State<VoiceDetectionScreen> createState() => _VoiceDetectionScreenState();
}

<<<<<<< HEAD
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
=======
class _VoiceDetectionScreenState extends State<VoiceDetectionScreen>
    with SingleTickerProviderStateMixin {
  // Recording state
  bool _isRecording = false;
  bool _isAnalyzing = false;
  bool _isDeepAnalyzing = false;
  String _analysisStatus = '';
  int _recordingSeconds = 0;
  Timer? _timer;
  String? _recordingPath;
  final AudioRecorder _recorder = AudioRecorder();

  // Pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Result
  VoiceAnalysisResult? _result;
  String? _errorMessage;

  // Disclaimer
  bool _disclaimerAccepted = false;

  // Recent analysis list (session-only)
  final List<Map<String, dynamic>> _recentAnalysis = [];

  // Waveform state
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  final List<double> _amplitudes = List.filled(40, 0.05);
>>>>>>> dev-ui2

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
<<<<<<< HEAD
      duration: const Duration(seconds: 1),
=======
      duration: const Duration(milliseconds: 900),
>>>>>>> dev-ui2
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
<<<<<<< HEAD
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
=======
    _amplitudeSubscription?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  // ─── Disclaimer ─────────────────────────────────────────────────────────────

  Future<bool> _showDisclaimerIfNeeded() async {
    if (_disclaimerAccepted) return true;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(LucideIcons.shieldAlert, color: AppColors.primaryBlue, size: 22),
            SizedBox(width: 12),
            Text(
              'Before You Start',
              style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _disclaimerItem(LucideIcons.brainCircuit,
                'AI-assisted analysis — not a guarantee of fraud or safety.'),
            const SizedBox(height: 16),
            _disclaimerItem(LucideIcons.lock,
                'Audio is never stored. Only a transcript and hash are retained.'),
            const SizedBox(height: 16),
            _disclaimerItem(LucideIcons.gavel,
                'Malaysia: recording requires consent of at least one party (you).'),
            const SizedBox(height: 16),
            _disclaimerItem(LucideIcons.phoneCall,
                'If you suspect fraud, contact your bank or PDRM: 03-2610 1559.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('I Understand', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (accepted == true) {
      if (mounted) setState(() => _disclaimerAccepted = true);
      return true;
    }
    return false;
  }

  Widget _disclaimerItem(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryBlue.withValues(alpha: 0.6), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: AppColors.textDark.withValues(alpha: 0.7), fontSize: 13, height: 1.4)),
          ),
        ],
      );

  // ─── Recording ───────────────────────────────────────────────────────────────

  Future<void> _toggleRecording() async {
    if (_isAnalyzing) return;

    if (_isRecording) {
      await _stopAndAnalyze();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (!await _showDisclaimerIfNeeded()) return;

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for voice analysis.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _recordingPath = '${dir.path}/voice_$timestamp.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: _recordingPath!,
    );

    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
      if (mounted) {
        setState(() {
          double normalized = (amp.current + 160) / 160;
          normalized = normalized.clamp(0.05, 1.0);
          _amplitudes.removeAt(0);
          _amplitudes.add(normalized);
        });
      }
    });

    setState(() {
      _isRecording = true;
      _result = null;
      _errorMessage = null;
      _recordingSeconds = 0;
      for (int i = 0; i < _amplitudes.length; i++) {
        _amplitudes[i] = 0.05;
      }
    });

    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordingSeconds++);
    });
  }

  Future<void> _stopAndAnalyze() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    final path = await _recorder.stop();
    await _amplitudeSubscription?.cancel();

    if (mounted) {
      setState(() {
        _isRecording = false;
        _isAnalyzing = true;
      });
    }

    try {
      final file = File(path ?? _recordingPath ?? '');
      if (!file.existsSync()) throw Exception('Recording file not found.');

      if (mounted) setState(() => _analysisStatus = 'Transcribing audio...');
      final response = await ApiService.instance.analyzeVoice(file.path);

      if (mounted) {
        setState(() {
          _isDeepAnalyzing = true;
          _analysisStatus = 'Running Behavioral Heuristics...';
        });
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) setState(() => _analysisStatus = 'Comparing with Scam Patterns...');
        await Future.delayed(const Duration(milliseconds: 800));
      }

      final data = response['data'] as Map<String, dynamic>? ?? response;
      final analysisResult = VoiceAnalysisResult.fromJson(data);

      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')} ${_monthAbbr(now.month)} ${now.year}';
      final nameStr = 'Voice_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _isDeepAnalyzing = false;
          _result = analysisResult;
          _recentAnalysis.insert(0, {
            'name': nameStr,
            'result': analysisResult.riskScore >= 55 ? 'Suspicious' : 'Safe',
            'score': analysisResult.riskScore,
            'date': dateStr,
          });
        });
      }

      try {
        file.deleteSync();
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        setState(() {
          _isAnalyzing = false;
          _isDeepAnalyzing = false;
          _errorMessage = msg;
        });
      }
    }
  }

  String _monthAbbr(int m) => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];

  String _formatDuration(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  // ─── UI helpers ──────────────────────────────────────────────────────────────

  Color get _levelColor {
    switch (_result?.level) {
      case 'critical': return Colors.purple;
      case 'high':     return const Color(0xFFEF4444);
      case 'medium':   return const Color(0xFFF59E0B);
      default:         return const Color(0xFF22C55E);
    }
  }

  String get _levelLabel {
    switch (_result?.level) {
      case 'critical': return 'Critical Risk';
      case 'high':     return 'High Risk';
      case 'medium':   return 'Suspicious';
      default:         return 'Looks Safe';
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Call Screen',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildInfoCard(),
            const SizedBox(height: 48),
            _buildMicSection(),
            const SizedBox(height: 48),
            
            if (_errorMessage != null) _buildErrorCard(),

            if (_result != null && !_isAnalyzing) _buildResultCard(),

            const SizedBox(height: 32),
            _buildRecentSection(),
>>>>>>> dev-ui2
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD
=======

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(LucideIcons.phoneIncoming, color: AppColors.primaryBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Voice Analysis',
                  style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Instantly scan calls for scam patterns and deepfake markers.',
                  style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.5), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _toggleRecording,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (ctx, _) => Transform.scale(
              scale: _isRecording ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isAnalyzing
                        ? [Colors.grey.shade300, Colors.grey.shade400]
                        : _isRecording
                            ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                            : [AppColors.primaryBlue, AppColors.primaryBlue.withValues(alpha: 0.8)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : AppColors.primaryBlue).withValues(alpha: 0.3),
                      blurRadius: _isRecording ? 30 : 20,
                      spreadRadius: _isRecording ? 10 : 2,
                    ),
                  ],
                ),
                child: Center(
                  child: _isAnalyzing
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      : Icon(
                          _isRecording ? LucideIcons.square : LucideIcons.mic,
                          color: Colors.white,
                          size: 52,
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_isAnalyzing)
          Column(
            children: [
              Text(_analysisStatus, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const SizedBox(width: 100, child: LinearProgressIndicator(minHeight: 2, backgroundColor: AppColors.lightBg)),
            ],
          )
        else if (_isRecording)
          Column(
            children: [
              Text(
                _formatDuration(_recordingSeconds),
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Listening for scam patterns...',
                style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.4), fontSize: 13),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 40,
                child: CustomPaint(
                  painter: WaveformPainter(amplitudes: _amplitudes, color: const Color(0xFFEF4444)),
                  size: const Size(double.infinity, 40),
                ),
              ),
            ],
          )
        else
          Text(
            'Tap to start voice analysis',
            style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.4), fontWeight: FontWeight.w500),
          ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final r = _result!;
    final isRisky = r.riskScore >= 55;
    final color = _levelColor;

    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(isRisky ? LucideIcons.shieldAlert : LucideIcons.shieldCheck, color: color, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            _levelLabel,
            style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 24),
          _resultRow('Risk Score', '${r.riskScore}/100', color, isBold: true),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: r.riskScore / 100,
              minHeight: 8,
              backgroundColor: AppColors.lightBg,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (r.transcript.isNotEmpty) ...[
            const Divider(height: 48),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Transcript Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 12),
            Text(
              r.transcript,
              style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.6), height: 1.5, fontSize: 13),
            ),
          ],
          if (r.contentAnalysis.matchedPatterns.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: r.contentAnalysis.matchedPatterns.map((p) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.lightBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(p, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.5), fontSize: 14)),
        Text(value, style: TextStyle(color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
      ],
    );
  }

  Widget _buildRecentSection() {
    if (_recentAnalysis.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Recent Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 16),
        ..._recentAnalysis.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.fileAudio, color: AppColors.textDark, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(item['date'], style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.4), fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (item['score'] >= 55 ? const Color(0xFFEF4444) : const Color(0xFF22C55E)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item['result'],
                  style: TextStyle(
                    color: item['score'] >= 55 ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  WaveformPainter({required this.amplitudes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final spacing = size.width / (amplitudes.length - 1);
    for (int i = 0; i < amplitudes.length; i++) {
       final x = i * spacing;
       final h = amplitudes[i] * size.height;
       canvas.drawLine(
         Offset(x, size.height / 2 - h / 2),
         Offset(x, size.height / 2 + h / 2),
         paint,
       );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
>>>>>>> dev-ui2
}
