import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/colors.dart';
import '../services/risk_evaluator.dart';
import '../l10n/app_localizations.dart';

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
      case 'critical': return Colors.purple;
      case 'high': return const Color(0xFFEF4444);
      case 'medium': return const Color(0xFFF59E0B);
      default: return const Color(0xFF22C55E);
    }
  }

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
          'AI File Scanner',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildActionCard(),
            const SizedBox(height: 32),
            if (_isLoading) _buildLoadingState(),
            if (_errorMessage != null) _buildErrorCard(),
            if (_result != null && !_isLoading) _buildResultCard(),
            const SizedBox(height: 32),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.fileSearch, color: AppColors.primaryBlue, size: 32),
          ),
          const SizedBox(height: 20),
          const Text(
            'Scan PDF or APK',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload suspicious files to detect hidden phishing links, malware markers, and dangerous permissions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.5), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAndScanFile,
              icon: const Icon(LucideIcons.upload, size: 18),
              label: const Text('Select File', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const CircularProgressIndicator(color: AppColors.primaryBlue),
        const SizedBox(height: 16),
        Text(
          'Deep scanning $_selectedFileName...',
          style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
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
    final res = _result!;
    final color = _getLevelColor(res.level);
    final isRisky = res.score >= 55;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(isRisky ? LucideIcons.shieldAlert : LucideIcons.shieldCheck, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    res.level.toUpperCase(),
                    style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
                  ),
                  Text('Security Analysis Complete', style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.4), fontSize: 12)),
                ],
              ),
              const Spacer(),
              Text(
                '${res.score}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Analysis Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...res.reasons.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.checkCircle2, color: isRisky ? Colors.red.withValues(alpha: 0.5) : Colors.green, size: 14),
                const SizedBox(width: 10),
                Expanded(child: Text(r, style: TextStyle(fontSize: 13, color: AppColors.textDark.withValues(alpha: 0.7)))),
              ],
            ),
          )),
          
          if (res.extractedLinks.isNotEmpty) ...[
            const Divider(height: 32),
            const Text('Embedded Links Detected', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: res.extractedLinks.map((link) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(link, style: const TextStyle(fontSize: 11, color: AppColors.primaryBlue, decoration: TextDecoration.underline)),
                  )).toList(),
                ),
              ),
            ),
          ],

          if (res.dangerousPermissions.isNotEmpty) ...[
            const Divider(height: 32),
            const Text('Dangerous Permissions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: res.dangerousPermissions.map((p) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(p.split('.').last, style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
              )).toList(),
            ),
          ],

          const Divider(height: 32),
          _detailRow('File Name', _selectedFileName ?? '-'),
          _detailRow('SHA-256', res.sha256 != null ? '${res.sha256!.substring(0, 8)}...${res.sha256!.substring(res.sha256!.length - 8)}' : '-'),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.4), fontSize: 12)),
          Text(value, style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Scans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        ..._history.map((item) {
          final color = _getLevelColor(item['level']);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(item['name'].endsWith('.apk') ? LucideIcons.package : LucideIcons.fileText, color: AppColors.textDark, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(item['level'].toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                Text('${item['score']}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
