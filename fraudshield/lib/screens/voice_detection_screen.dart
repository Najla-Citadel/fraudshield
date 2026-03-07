import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../design_system/components/app_loading_indicator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../widgets/glass_surface.dart';
import '../design_system/components/app_button.dart';
import '../services/api_service.dart';
import '../design_system/components/app_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

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
  final bool autoStart;
  const VoiceDetectionScreen({super.key, this.autoStart = false});

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

  // Recent analysis list (session-only)
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
    _initForegroundTask();

    // Mark voice scan as active globally to suppress overlays and duplicate routing
    NotificationService.instance.setVoiceScanActive(true);

    if (widget.autoStart) {
      _handleAutoStart();
    }
  }

  Future<void> _handleAutoStart() async {
    // Small delay to let animations/overlay settle
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      await _startRecording();
    }
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'fraudshield_background',
        channelName: 'FraudShield Protection',
        channelDescription: 'Maintains recording protection during calls',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
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

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('voice_scan_disclaimer_accepted') == true) {
      if (mounted) setState(() => _disclaimerAccepted = true);
      return true;
    }

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.colors.backgroundDark,
        surfaceTintColor: DesignTokens.colors.backgroundDark,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radii.xl)),
        title: Row(
          children: [
            Icon(LucideIcons.alertTriangle,
                color: DesignTokens.colors.primary, size: 22),
            SizedBox(width: 12),
            Text(
              'Before You Start',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _disclaimerItem(LucideIcons.brainCircuit,
                'AI-assisted analysis — not a guarantee of fraud or safety.'),
            SizedBox(height: 16),
            _disclaimerItem(LucideIcons.lock,
                'Audio is never stored. Only a transcript and hash are retained.'),
            SizedBox(height: 16),
            _disclaimerItem(LucideIcons.gavel,
                'Malaysia: recording requires consent of at least one party (you).'),
            SizedBox(height: 16),
            _disclaimerItem(LucideIcons.volume2,
                'Important: Please put your call on Speaker so the microphone can hear the scammer.'),
            SizedBox(height: 16),
            _disclaimerItem(LucideIcons.phoneCall,
                'If you suspect fraud, contact your bank or PDRM: 03-2610 1559.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5))),
          ),
          AppButton(
            onPressed: () => Navigator.pop(ctx, true),
            label: 'I Understand',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.sm,
          ),
        ],
      ),
    );
    if (accepted == true) {
      if (mounted) setState(() => _disclaimerAccepted = true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('voice_scan_disclaimer_accepted', true);
      return true;
    }
    return false;
  }

  Widget _disclaimerItem(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: DesignTokens.colors.primary.withOpacity(0.6), size: 18),
          SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.4)),
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
        AppSnackBar.showError(context, 'Microphone permission is required for voice analysis.');
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

    // Start Foreground Task
    if (await FlutterForegroundTask.canDrawOverlays) {
      await FlutterForegroundTask.startService(
        notificationTitle: 'FraudShield Active',
        notificationText: 'Analyzing call for threats...',
      );
    }

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

    // Stop Foreground Task
    await FlutterForegroundTask.stopService();

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
        if (mounted) {
          setState(() => _analysisStatus = 'Comparing with Scam Patterns...');
        }
        await Future.delayed(const Duration(milliseconds: 800));
      }

      final data = response['data'] as Map<String, dynamic>? ?? response;
      final analysisResult = VoiceAnalysisResult.fromJson(data);

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

  String _monthAbbr(int m) => [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m - 1];

  String _formatDuration(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  // ─── UI helpers ──────────────────────────────────────────────────────────────

  Color get _levelColor {
    switch (_result?.level) {
      case 'critical':
        return DesignTokens.colors.error;
      case 'high':
        return DesignTokens.colors.error;
      case 'medium':
        return DesignTokens.colors.warning;
      default:
        return DesignTokens.colors.accentGreen;
    }
  }

  String get _levelLabel {
    switch (_result?.level) {
      case 'critical':
        return 'Critical Risk';
      case 'high':
        return 'High Risk';
      case 'medium':
        return 'Suspicious';
      default:
        return 'Looks Safe';
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Release the global lock when leaving this screen
        NotificationService.instance.setVoiceScanActive(false);
      },
      child: ScreenScaffold(
        title: 'CALL SCREEN',
        body: SingleChildScrollView(
          padding: EdgeInsets.all(DesignTokens.spacing.xxl),
          child: Column(
            children: [
              _buildInfoCard(),
              SizedBox(height: 48),
              _buildMicSection(),
              SizedBox(height: 48),
              if (_errorMessage != null) _buildErrorCard(),
              if (_result != null && !_isAnalyzing) _buildResultCard(),
              SizedBox(height: 32),
              _buildRecentSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return GlassSurface(
      padding: EdgeInsets.all(DesignTokens.spacing.xl),
      borderRadius: 24,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.spacing.md),
            decoration: BoxDecoration(
              color: DesignTokens.colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radii.md),
            ),
            child: Icon(LucideIcons.phoneIncoming,
                color: DesignTokens.colors.primary, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Analysis',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                Text(
                  'Instantly scan calls for scam patterns and deepfake markers.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12),
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
          onTap: _isAnalyzing ? null : _toggleRecording,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (ctx, _) => Transform.scale(
              scale: _isRecording ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isAnalyzing
                        ? [Colors.grey.shade300, Colors.grey.shade400]
                        : _isRecording
                            ? [
                                DesignTokens.colors.error,
                                DesignTokens.colors.critical
                              ]
                            : [
                                DesignTokens.colors.primary,
                                DesignTokens.colors.primary.withOpacity(0.8)
                              ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording
                              ? DesignTokens.colors.error
                              : DesignTokens.colors.primary)
                          .withOpacity(0.3),
                      blurRadius: _isRecording ? 30 : 20,
                      spreadRadius: _isRecording ? 10 : 2,
                    ),
                  ],
                ),
                child: Center(
                  child: _isAnalyzing
                      ? AppLoadingIndicator(color: DesignTokens.colors.accentGreen)
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
        SizedBox(height: 24),
        if (_isAnalyzing)
          Column(
            children: [
              Text(_analysisStatus,
                  style: TextStyle(
                      color: DesignTokens.colors.primary,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              SizedBox(
                width: 100,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor:
                      DesignTokens.colors.glassDark.withOpacity(0.4),
                ),
              ),
            ],
          )
        else if (_isRecording)
          Column(
            children: [
              Text(
                _formatDuration(_recordingSeconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please put call on Speaker for best results',
                style: TextStyle(
                    color: DesignTokens.colors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Listening for scam patterns...',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 13),
              ),
              SizedBox(height: 20),
              SizedBox(
                height: 40,
                child: CustomPaint(
                  painter: WaveformPainter(
                      amplitudes: _amplitudes, color: DesignTokens.colors.error),
                  size: const Size(double.infinity, 40),
                ),
              ),
            ],
          )
        else
          Text(
            'Tap to start voice analysis',
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontWeight: FontWeight.w500),
          ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: EdgeInsets.only(top: DesignTokens.spacing.xxl),
      padding: EdgeInsets.all(DesignTokens.spacing.lg),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(DesignTokens.radii.md),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, color: Colors.red, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(_errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
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
      margin: EdgeInsets.only(top: DesignTokens.spacing.xxxl),
      child: GlassSurface(
        padding: EdgeInsets.all(DesignTokens.spacing.xxl),
        borderRadius: 28,
        borderColor: color.withOpacity(0.15),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(DesignTokens.spacing.lg),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                  isRisky ? LucideIcons.shieldAlert : LucideIcons.shieldCheck,
                  color: color,
                  size: 40),
            ),
            SizedBox(height: 16),
            Text(
              _levelLabel,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 24),
            _resultRow('Risk Score', '${r.riskScore}/100', color, isBold: true),
            SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
              child: LinearProgressIndicator(
                value: r.riskScore / 100,
                minHeight: 8,
                backgroundColor: DesignTokens.colors.glassDark.withOpacity(0.4),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            if (r.transcript.isNotEmpty) ...[
              Divider(height: 48),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Transcript Analysis',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              SizedBox(height: 12),
              Text(
                r.transcript,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    height: 1.5,
                    fontSize: 13),
              ),
            ],
            if (r.contentAnalysis.matchedPatterns.isNotEmpty) ...[
              SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: r.contentAnalysis.matchedPatterns
                    .map((p) => Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                DesignTokens.colors.glassDark.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(DesignTokens.radii.xs),
                          ),
                          child: Text(p,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value, Color color,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14)),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 14)),
      ],
    );
  }

  Widget _buildRecentSection() {
    if (_recentAnalysis.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Analysis',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        SizedBox(height: 16),
        ..._recentAnalysis.map((item) => Container(
              margin: EdgeInsets.only(bottom: DesignTokens.spacing.md),
              child: GlassSurface(
                padding: EdgeInsets.all(DesignTokens.spacing.lg),
                child: Row(
                  children: [
                    Icon(LucideIcons.fileAudio,
                        color: Colors.white, size: 20),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          Text(item['date'],
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacing.sm, vertical: DesignTokens.spacing.xs),
                      decoration: BoxDecoration(
                        color: (item['score'] >= 55
                                ? DesignTokens.colors.error
                                : DesignTokens.colors.accentGreen)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radii.xs),
                      ),
                      child: Text(
                        item['result'],
                        style: TextStyle(
                          color: item['score'] >= 55
                              ? DesignTokens.colors.error
                              : DesignTokens.colors.accentGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
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
}
