import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import 'report_history_screen.dart';
import '../widgets/selection_sheet.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/adaptive_text_field.dart';

class ScamReportingScreen extends StatefulWidget {
  const ScamReportingScreen({super.key});

  @override
  State<ScamReportingScreen> createState() => _ScamReportingScreenState();
}

class _ScamReportingScreenState extends State<ScamReportingScreen> {
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Investment Scam';
  bool _reportSent = false;
  String _reportType = 'Phone';
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isPublic = true;

  final List<String> _reportTypes = [
    'Phone',
    'Message',
    'Document',
    'Others',
  ];

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      log('Error picking file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... confirmation screen stays same ...
    if (_reportSent) {
      return AdaptiveScaffold(
        title: 'Report Sent',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 90),
                const SizedBox(height: 20),
                const Text(
                  'Your scam report is successfully sent!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'We will verify your report and inform you once any follow-up action has been taken.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                AdaptiveButton(
                  text: 'Got It',
                  onPressed: () {
                    setState(() {
                      _reportSent = false;
                      _phoneController.clear();
                      _descController.clear();
                      _selectedFilePath = null;
                      _selectedFileName = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AdaptiveScaffold(
      title: 'Scam Reporting',
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'Report History',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ReportHistoryScreen(),
              ),
            );
          },
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Hero(
                tag: 'hero_report',
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  child: Image.asset('assets/icons/report.png', width: 40),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Reports may be shared with relevant authorities for review',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final selected = await SelectionSheet.show<String>(
                  context: context,
                  title: 'Select Report Type',
                  options: _reportTypes,
                  labelBuilder: (val) => val,
                );
                if (selected != null) {
                  setState(() => _reportType = selected);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_reportType, style: const TextStyle(fontSize: 16)),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_reportType == 'Phone') ...[
              AdaptiveTextField(
                controller: _phoneController,
                label: 'Phone Number',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
            ],
            if (_reportType == 'Others') ...[
              AdaptiveTextField(
                controller: _descController,
                label: 'Describe the issue',
                maxLines: 3,
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Scam Category',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final categories = [
                  'Investment Scam',
                  'Fake Giveaway / Promo Scam',
                  'Phishing Scam',
                  'Job Scam',
                  'Love Scam',
                ];
                final selected = await SelectionSheet.show<String>(
                  context: context,
                  title: 'Select Scam Category',
                  options: categories,
                  labelBuilder: (val) => val,
                );
                if (selected != null) {
                  setState(() => _selectedCategory = selected);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_selectedCategory, style: const TextStyle(fontSize: 16)),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            AdaptiveTextField(
              controller: _descController,
              label: 'Description',
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickFile,
                icon: Icon(_selectedFileName != null ? Icons.check : Icons.upload_file),
                label: Text(_selectedFileName ?? 'Upload Evidence (Optional)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.primaryBlue),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text(
                'Share with the community',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Help others by sharing an anonymized version of this report in the public feed.',
                style: TextStyle(fontSize: 12),
              ),
              value: _isPublic,
              activeColor: AppColors.primaryBlue,
              onChanged: (val) => setState(() => _isPublic = val),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: AdaptiveButton(
                text: 'Submit',
                onPressed: () async {
                  bool isPhoneValid = _reportType != 'Phone' || _phoneController.text.trim().isNotEmpty;
                  if (!isPhoneValid || _descController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in all required fields.')),
                    );
                    return;
                  }

                  String? uploadedUrl;
                  if (_selectedFilePath != null) {
                    try {
                      final uploadRes = await ApiService.instance.uploadFile(_selectedFilePath!);
                      uploadedUrl = uploadRes['url'];
                    } catch (e) {
                      log('Error uploading file: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to upload evidence: $e')),
                        );
                      }
                      return;
                    }
                  }

                  setState(() {
                    _reportSent = true;
                  });

                  try {
                    await ApiService.instance.submitScamReport(
                      type: _reportType,
                      category: _selectedCategory,
                      description: _descController.text.trim(),
                      target: _reportType == 'Phone' ? _phoneController.text.trim() : null, // Captured target
                      isPublic: _isPublic, // User preference
                      evidence: {
                        if (_reportType == 'Phone') 'phone': _phoneController.text.trim(),
                        if (uploadedUrl != null) 'evidence_url': uploadedUrl,
                        'desc_issue': _descController.text.trim(),
                      },
                    );
                  } catch (e) {
                    log('Error submitting report: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to submit report: $e')),
                      );
                      setState(() {
                        _reportSent = false;
                      });
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
