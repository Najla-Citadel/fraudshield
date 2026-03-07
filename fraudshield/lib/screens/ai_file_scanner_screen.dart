import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../design_system/components/app_loading_indicator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../design_system/components/app_button.dart';
import '../widgets/glass_surface.dart';
import '../services/risk_evaluator.dart';

class AIFileScannerScreen extends StatefulWidget {
  const AIFileScannerScreen({super.key});

  @override
  State<AIFileScannerScreen> createState() => _AIFileScannerScreenState();
}

class _AIFileScannerScreenState extends State<AIFileScannerScreen> {
  bool _isLoading = false;
  RiskResult? _result;
  String? _selectedFileName;
  String? _selectedFilePath;
  String? _errorMessage;

  // Session-based history
  final List<Map<String, dynamic>> _history = [];

  Future<void> _pickAndScanFile() async {
    setState(() {
      _errorMessage = null;
      _result = null;
    });

    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'apk'],
        withData: false,
      );

      if (picked == null || picked.files.isEmpty || picked.files.first.path == null) {
        return;
      }

      final filePath = picked.files.first.path!;
      final fileName = picked.files.first.name;

      setState(() {
        _isLoading = true;
        _selectedFileName = fileName;
        _selectedFilePath = filePath;
      });

      final result = await RiskEvaluator.evaluateDocument(filePath);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _result = result;
          _history.insert(0, {
            'name': fileName,
            'score': result.score,
            'level': result.level,
            'time': DateTime.now(),
          });
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'AI FILE SCANNER',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DesignTokens.spacing.xxl),
        child: Column(
          children: [
            _buildActionCard(),
            SizedBox(height: 32),
            if (_isLoading) _buildLoadingState(),
            if (_errorMessage != null) _buildErrorCard(),
            if (_result != null && !_isLoading) _buildResultCard(),
            SizedBox(height: 32),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard() {
    return GlassSurface(
      padding: EdgeInsets.all(DesignTokens.spacing.xxl),
      borderRadius: 28,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.spacing.lg),
            decoration: BoxDecoration(
              color: DesignTokens.colors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.fileSearch,
                color: DesignTokens.colors.primary, size: 32),
          ),
          SizedBox(height: 20),
          Text(
            'Scan PDF or APK',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Upload suspicious files to detect hidden phishing links, malware markers, and dangerous permissions.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.5),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              onPressed: _isLoading ? null : _pickAndScanFile,
              icon: LucideIcons.upload,
              label: 'Select File',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        AppLoadingIndicator.center(color: DesignTokens.colors.primary),
        SizedBox(height: 16),
        Text(
          'Deep scanning $_selectedFileName...',
          style: TextStyle(
              color: DesignTokens.colors.primary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
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
            child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final res = _result!;
    final color = _getLevelColor(res.level);
    final isRisky = res.score >= 55;

    return GlassSurface(
      padding: EdgeInsets.all(DesignTokens.spacing.xxl),
      borderRadius: 28,
      borderColor: color.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spacing.md),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(isRisky ? LucideIcons.shieldAlert : LucideIcons.shieldCheck, color: color, size: 28),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    res.level.toUpperCase(),
                    style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
                  ),
                  Text('Security Analysis Complete', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                ],
              ),
              Spacer(),
              Text(
                '${res.score}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 24),
              ),
            ],
          ),
          SizedBox(height: 24),
          Text('Analysis Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 12),
            ...res.reasons.map((r) => Padding(
                  padding: EdgeInsets.only(bottom: DesignTokens.spacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.checkCircle2,
                          color: isRisky
                              ? DesignTokens.colors.error.withOpacity(0.5)
                              : DesignTokens.colors.accentGreen,
                          size: 14),
                      SizedBox(width: 10),
                      Expanded(
                          child: Text(r,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.7)))),
                    ],
                  ),
                )),
          
          if (res.extractedLinks.isNotEmpty) ...[
            Divider(height: 32),
            Text('Embedded Links Detected', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: EdgeInsets.all(DesignTokens.spacing.md),
              decoration: BoxDecoration(
                color: DesignTokens.colors.glassDark.withOpacity(0.4),
                borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: res.extractedLinks
                      .map((link) => Padding(
                            padding: EdgeInsets.only(bottom: DesignTokens.spacing.xs),
                            child: Text(link,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: DesignTokens.colors.primary,
                                    decoration: TextDecoration.underline)),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],

          if (res.dangerousPermissions.isNotEmpty) ...[
            Divider(height: 32),
            Text('Dangerous Permissions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: res.dangerousPermissions.map((p) => Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(DesignTokens.radii.xs),
                ),
                child: Text(p.split('.').last, style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
              )).toList(),
            ),
          ],

          Divider(height: 32),
          _detailRow('File Name', _selectedFileName ?? '-'),
          _detailRow('SHA-256', res.sha256 != null ? '${res.sha256!.substring(0, 8)}...${res.sha256!.substring(res.sha256!.length - 8)}' : '-'),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_history.isEmpty) return SizedBox.shrink();
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Scans',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 16),
        ..._history.map((item) {
          final color = _getLevelColor(item['level']);
          return Container(
            margin: EdgeInsets.only(bottom: DesignTokens.spacing.md),
            child: GlassSurface(
              padding: EdgeInsets.all(DesignTokens.spacing.lg),
              child: Row(
                children: [
                  Icon(
                      item['name'].endsWith('.apk')
                          ? LucideIcons.package
                          : LucideIcons.fileText,
                      color: Colors.white,
                      size: 20),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['name'],
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(item['level'].toUpperCase(),
                            style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  Text('${item['score']}%',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
