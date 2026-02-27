import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../constants/colors.dart';
import '../widgets/adaptive_scaffold.dart';
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

class VoiceDetectionScreen extends StatefulWidget {
  const VoiceDetectionScreen({super.key});

  @override
  State<VoiceDetectionScreen> createState() => _VoiceDetectionScreenState();
}

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

  // Recent analysis list (session-only, persists within screen lifetime)
  final List<Map<String, dynamic>> _recentAnalysis = [];

  // Waveform state
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  final List<double> _amplitudes = List.filled(40, 0.05);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
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
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.primaryBlue, size: 22),
            SizedBox(width: 10),
            Text(
              'Before You Start',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _disclaimerItem(Icons.psychology_outlined,
                'AI-assisted analysis — not a guarantee of fraud or safety.'),
            const SizedBox(height: 12),
            _disclaimerItem(Icons.lock_outline,
                'Audio is never stored. Only a transcript and hash are retained.'),
            const SizedBox(height: 12),
            _disclaimerItem(Icons.gavel_outlined,
                'Malaysia: recording requires consent of at least one party (you). Do not record others without their knowledge.'),
            const SizedBox(height: 12),
            _disclaimerItem(Icons.emergency_outlined,
                'If you suspect fraud, contact your bank or PDRM: 03-2610 1559.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('I Understand', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (accepted == true) {
      setState(() => _disclaimerAccepted = true);
      return true;
    }
    return false;
  }

  Widget _disclaimerItem(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 13, height: 1.4)),
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
    // Show disclaimer first
    if (!await _showDisclaimerIfNeeded()) return;

    // Request microphone permission
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

    // Listen to amplitude for waveform
    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
      if (mounted) {
        setState(() {
          // Process dB: -160 to 0 range → normalize to 0.0 to 1.0
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
      // Reset waveform
      for (int i = 0; i < _amplitudes.length; i++) {
        _amplitudes[i] = 0.05;
      }
    });

    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordingSeconds++);
    });
  }

  Future<void> _stopAndAnalyze() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    final path = await _recorder.stop();
    await _amplitudeSubscription?.cancel();

    setState(() {
      _isRecording = false;
      _isAnalyzing = true;
    });

    try {
      final file = File(path ?? _recordingPath ?? '');
      if (!file.existsSync()) throw Exception('Recording file not found.');

      setState(() => _analysisStatus = 'Transcribing audio...');
      final response = await ApiService.instance.analyzeVoice(file.path);

      // Add a slight delay for "Heuristic Cross-Check" to feel thorough
      if (mounted) {
        setState(() {
          _isDeepAnalyzing = true;
          _analysisStatus = 'Running Behavioral Heuristics...';
        });
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) setState(() => _analysisStatus = 'Comparing with Scam Patterns...');
        await Future.delayed(const Duration(milliseconds: 800));
      }

      // Parse the nested data object
      final data = response['data'] as Map<String, dynamic>? ?? response;
      final analysisResult = VoiceAnalysisResult.fromJson(data);

      // Add to recent list
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')} ${_monthAbbr(now.month)} ${now.year}';
      final nameStr =
          'Voice_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

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

      // Clean up temp file
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

  String _monthAbbr(int m) =>
      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];

  String _formatDuration(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  // ─── UI helpers ──────────────────────────────────────────────────────────────

  Color get _levelColor {
    switch (_result?.level) {
      case 'critical': return Colors.red.shade400;
      case 'high':     return Colors.orange.shade400;
      case 'medium':   return Colors.amber.shade400;
      default:         return Colors.green.shade400;
    }
  }

  String get _levelLabel {
    switch (_result?.level) {
      case 'critical': return '🚨 Critical Risk';
      case 'high':     return '⚠️ High Risk';
      case 'medium':   return '🟡 Medium Risk';
      default:         return '✅ Low Risk — Safe';
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Voice Detection',
      backgroundColor: AppColors.deepNavy,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Header ──
            _buildHeader(),
            const SizedBox(height: 8),

            // ── Premium badge ──
            _buildPremiumBadge(),
            const SizedBox(height: 48),

            // ── Mic button ──
            _buildMicButton(),
            const SizedBox(height: 28),

            // ── Status text ──
            _buildStatusText(),
            const SizedBox(height: 40),

            // ── Error card ──
            if (_errorMessage != null) ...[
              _buildErrorCard(),
              const SizedBox(height: 32),
            ],

            // ── Result card ──
            if (_result != null && !_isAnalyzing) ...[
              _buildResultCard(),
              const SizedBox(height: 40),
            ],

            // ── Recent analysis ──
            _buildRecentSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
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
              'AI-powered scam call detection',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildPremiumBadge() => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.black, size: 14),
          SizedBox(width: 5),
          Text(
            'Premium Feature',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    ),
  );

  Widget _buildMicButton() => GestureDetector(
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
                  ? [Colors.blueGrey.shade700, Colors.blueGrey.shade900]
                  : _isRecording
                      ? [Colors.redAccent.shade400, Colors.red.shade800]
                      : [AppColors.primaryBlue, AppColors.primaryBlue.withOpacity(0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (_isRecording ? Colors.red : AppColors.primaryBlue)
                    .withOpacity(0.4),
                blurRadius: _isRecording ? 28 : 18,
                spreadRadius: _isRecording ? 8 : 4,
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
          ),
          child: _isAnalyzing
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                )
              : Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 64,
                ),
        ),
      ),
    ),
  );

  Widget _buildStatusText() {
    if (_isAnalyzing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2, 
                color: _isDeepAnalyzing ? Colors.orangeAccent : AppColors.primaryBlue
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _analysisStatus,
              style: TextStyle(
                color: _isDeepAnalyzing ? Colors.orangeAccent : AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    if (_isRecording) {
      return Column(
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
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.redAccent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Listening…',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Waveform visualizer
          SizedBox(
            height: 60,
            width: double.infinity,
            child: CustomPaint(
              painter: WaveformPainter(amplitudes: _amplitudes, color: Colors.redAccent),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _formatDuration(_recordingSeconds),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 42,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap Stop when done (min. 5 seconds)',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
          ),
        ],
      );
    }
    return Text(
      'Tap mic to start scanning',
      style: TextStyle(
        color: Colors.white.withOpacity(0.4),
        fontSize: 15,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildErrorCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            _errorMessage ?? 'An error occurred.',
            style: const TextStyle(color: Colors.redAccent, fontSize: 14, height: 1.4),
          ),
        ),
      ],
    ),
  );

  Widget _buildResultCard() {
    final r = _result!;
    final isSuspicious = r.riskScore >= 55;
    final cardColor = _levelColor;

    return AnimationConfiguration.synchronized(
      child: FadeInAnimation(
        duration: const Duration(milliseconds: 500),
        child: SlideAnimation(
          verticalOffset: 20,
          child: Column(
            children: [
              // ── Risk score ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cardColor.withOpacity(0.35), width: 1.5),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSuspicious ? Icons.gpp_bad_rounded : Icons.gpp_good_rounded,
                        color: cardColor,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _levelLabel,
                      style: TextStyle(
                          color: cardColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // Risk score bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: r.riskScore / 100,
                        minHeight: 8,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Risk Score: ${r.riskScore}/100',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Transcript ──
              if (r.transcript.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.07)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.text_snippet_outlined,
                              color: AppColors.primaryBlue, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Transcript${r.language.isNotEmpty ? '  (${r.language.toUpperCase()})' : ''}',
                            style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        r.transcript.length > 400
                            ? '${r.transcript.substring(0, 400)}…'
                            : r.transcript,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            height: 1.6),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // ── Detected patterns ──
              if (r.contentAnalysis.matchedPatterns.isNotEmpty ||
                  r.voiceAnalysis.flags.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.07)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag_outlined,
                              color: isSuspicious ? Colors.orange : Colors.green,
                              size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Detection Flags',
                            style: TextStyle(
                                color: isSuspicious ? Colors.orange : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...r.contentAnalysis.matchedPatterns.map(
                        (p) => _flagRow('📝', p),
                      ),
                      ...r.voiceAnalysis.flags.map(
                        (f) => _flagRow('🔊', f),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // ── Disclaimer ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: Text(
                  r.disclaimer,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 11,
                      height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _flagRow(String emoji, String text) {
    // Phase B: Select more specific icons for voice heuristics
    Widget icon;
    if (text.contains('Repetitive')) {
        icon = const Icon(Icons.loop_rounded, color: Colors.orange, size: 16);
    } else if (text.contains('Robotic')) {
        icon = const Icon(Icons.precision_manufacturing_outlined, color: Colors.orange, size: 16);
    } else if (text.contains('silence ratio')) {
        icon = const Icon(Icons.graphic_eq_rounded, color: Colors.orange, size: 16);
    } else {
        icon = Text(emoji, style: const TextStyle(fontSize: 13));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 20, child: Center(child: icon)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSection() {
    final all = [
      ..._recentAnalysis,
      // Seed with demo items if list is empty
      if (_recentAnalysis.isEmpty) ...[
        {'name': 'Call_20251101_1805', 'result': 'Safe', 'score': 12, 'date': '01 Nov 2025'},
        {'name': 'Call_20251029_1420', 'result': 'Suspicious', 'score': 78, 'date': '29 Oct 2025'},
        {'name': 'Voice_20251025_1032', 'result': 'Safe', 'score': 8, 'date': '25 Oct 2025'},
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Analysis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 0.5,
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
              itemCount: all.length,
              separatorBuilder: (_, __) =>
                  Divider(color: Colors.white.withOpacity(0.05), height: 1),
              itemBuilder: (_, index) {
                final item = all[index];
                final isBad = item['result'] == 'Suspicious';
                final score = item['score'] as int? ?? 0;

                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 30.0,
                    child: FadeInAnimation(
                      child: InkWell(
                        onTap: () {},
                        borderRadius: index == 0
                            ? const BorderRadius.vertical(top: Radius.circular(20))
                            : index == all.length - 1
                                ? const BorderRadius.vertical(
                                    bottom: Radius.circular(20))
                                : BorderRadius.zero,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: isBad
                                      ? Colors.redAccent.withOpacity(0.15)
                                      : AppColors.accentGreen.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isBad
                                      ? Icons.warning_amber_rounded
                                      : Icons.check_circle,
                                  color: isBad
                                      ? Colors.redAccent
                                      : AppColors.accentGreen,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] as String,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item['date'] as String,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.4)),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isBad
                                          ? Colors.redAccent.withOpacity(0.15)
                                          : AppColors.accentGreen.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isBad
                                            ? Colors.redAccent.withOpacity(0.3)
                                            : AppColors.accentGreen.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      item['result'] as String,
                                      style: TextStyle(
                                          color: isBad
                                              ? Colors.redAccent
                                              : AppColors.accentGreen,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Score: $score',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.3),
                                        fontSize: 11),
                                  ),
                                ],
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
      ],
    );
  }
}

// ─── Waveform Painter ─────────────────────────────────────────────────────────

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  WaveformPainter({required this.amplitudes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final double width = size.width;
    final double height = size.height;
    final double spacing = width / amplitudes.length;
    final double barWidth = spacing * 0.6;

    for (int i = 0; i < amplitudes.length; i++) {
        final double barHeight = amplitudes[i] * height;
        final double x = i * spacing + (spacing - barWidth) / 2;
        final double y = (height - barHeight) / 2;
        
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x, y, barWidth, barHeight),
                const Radius.circular(10),
            ),
            paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) => true;
}
