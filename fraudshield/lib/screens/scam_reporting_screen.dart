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
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;

class ScamReportingScreen extends StatefulWidget {
  const ScamReportingScreen({super.key});

  @override
  State<ScamReportingScreen> createState() => _ScamReportingScreenState();
}

class _ScamReportingScreenState extends State<ScamReportingScreen> {
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedCategory = 'Investment Scam';
  bool _reportSent = false;
  String _reportType = 'Phone';
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isPublic = true;
  bool _isSubmitting = false;

  final List<String> _reportTypes = [
    'Phone',
    'Message',
    'Document',
    'Others',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

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

  Future<void> _submitReport() async {
    bool isPhoneValid = _reportType != 'Phone' || _phoneController.text.trim().isNotEmpty;
    if (!isPhoneValid || _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String? uploadedUrl;
    if (_selectedFilePath != null) {
      try {
        final uploadRes = await ApiService.instance.uploadFile(_selectedFilePath!);
        uploadedUrl = uploadRes['url'];
      } catch (e) {
        log('Error uploading file: $e');
        if (mounted) {
           setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload evidence: $e')),
          );
        }
        return;
      }
    }

    try {
      // Determine coordinates
      double? latitude;
      double? longitude;

      final manualLocation = _locationController.text.trim();
      
      if (manualLocation.isNotEmpty) {
        try {
          // Attempt to geocode the keyed-in location
          final locations = await geo.locationFromAddress(manualLocation);
          if (locations.isNotEmpty) {
            latitude = locations.first.latitude;
            longitude = locations.first.longitude;
            log('Geocoded "$manualLocation" to: $latitude, $longitude');
          }
        } catch (e) {
          log('Geocoding failed for "$manualLocation": $e');
        }
      }

      // Fallback to device GPS if manual geocoding failed or was empty
      if (latitude == null || longitude == null) {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
          latitude = position.latitude;
          longitude = position.longitude;
          log('Using GPS fallback: $latitude, $longitude');
        } catch (e) {
          log('Could not fetch GPS fallback coordinates: $e');
        }
      }

      await ApiService.instance.submitScamReport(
        type: _reportType,
        category: _selectedCategory,
        description: _descController.text.trim(),
        target: _reportType == 'Phone' ? _phoneController.text.trim() : null,
        isPublic: _isPublic,
        latitude: latitude,
        longitude: longitude,
        evidence: {
          if (_reportType == 'Phone') 'phone': _phoneController.text.trim(),
          if (uploadedUrl != null) 'evidence_url': uploadedUrl,
          'desc_issue': _descController.text.trim(),
          if (_locationController.text.trim().isNotEmpty)
            'location': _locationController.text.trim(),
        },
      );
      
      if (mounted) {
        setState(() {
          _reportSent = true;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      log('Error submitting report: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      _reportSent = false;
      _phoneController.clear();
      _descController.clear();
      _locationController.clear();
      _selectedFilePath = null;
      _selectedFileName = null;
      _isPublic = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_reportSent) return _buildSuccessScreen();

    return AdaptiveScaffold(
      title: 'Report Scam',
      backgroundColor: AppColors.deepNavy,
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded, color: Colors.white),
          tooltip: 'Report History',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportHistoryScreen()),
          ),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Warning Banner ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security_rounded, color: AppColors.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Official Report', 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('Reports are reviewed by authorities.', 
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Report Type ────────────────────────────────
            _SectionLabel(label: 'Report Details'),
            const SizedBox(height: 12),
            _DropdownButton(
              label: 'Report Type',
              value: _reportType,
              onTap: () async {
                final selected = await SelectionSheet.show<String>(
                  context: context,
                  title: 'Select Report Type',
                  options: _reportTypes,
                  labelBuilder: (val) => val,
                );
                if (selected != null) setState(() => _reportType = selected);
              },
            ),
            const SizedBox(height: 16),
             if (_reportType == 'Phone')
              AdaptiveTextField(
                  controller: _phoneController,
                  label: 'Scammer Phone Number',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  textColor: Colors.white,
              ),

             const SizedBox(height: 16),
            _DropdownButton(
              label: 'Category',
              value: _selectedCategory,
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
                if (selected != null) setState(() => _selectedCategory = selected);
              },
            ),
            const SizedBox(height: 16),

            // ── Location ────────────────────────────────────
            AdaptiveTextField(
              controller: _locationController,
              label: 'Your City / State (e.g. Johor Bahru, Johor)',
              prefixIcon: Icons.location_on_outlined,
              filled: true,
              fillColor: const Color(0xFF1E293B),
              textColor: Colors.white,
            ),
            const SizedBox(height: 24),

            // ── Description ────────────────────────────────
             _SectionLabel(label: 'Description & Evidence'),
             const SizedBox(height: 12),
               AdaptiveTextField(
                controller: _descController,
                label: 'Describe what happened...',
                maxLines: 5,
                filled: true,
                fillColor: const Color(0xFF1E293B),
                textColor: Colors.white,
              ),
            const SizedBox(height: 16),

             // ── File Upload ──────────────────────────────
             GestureDetector(
               onTap: _pickFile,
               child: Container(
                 width: double.infinity,
                 padding: const EdgeInsets.symmetric(vertical: 20),
                 decoration: BoxDecoration(
                   color: const Color(0xFF1E293B),
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(
                     color: _selectedFileName != null ? AppColors.accentGreen : Colors.white.withOpacity(0.1),
                     style: _selectedFileName != null ? BorderStyle.solid : BorderStyle.solid,
                   ),
                 ),
                 child: Column(
                   children: [
                     Icon(
                       _selectedFileName != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                       color: _selectedFileName != null ? AppColors.accentGreen : Colors.white54,
                       size: 32,
                     ),
                     const SizedBox(height: 8),
                     Text(
                       _selectedFileName ?? 'Upload Screenshot or Evidence',
                       style: TextStyle(
                         color:  _selectedFileName != null ? AppColors.accentGreen : Colors.white70,
                         fontSize: 14,
                         fontWeight: FontWeight.w500,
                       ),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                     if (_selectedFileName == null)
                       Padding(
                         padding: const EdgeInsets.only(top: 4),
                         child: Text(
                           '(Optional • Max 5MB)',
                           style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                         ),
                       ),
                   ],
                 ),
               ),
             ),
             const SizedBox(height: 24),

             // ── Community Share ──────────────────────────
             Container(
               decoration: BoxDecoration(
                 color: const Color(0xFF1E293B),
                 borderRadius: BorderRadius.circular(16),
               ),
               child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  title: const Text(
                    'Share with Community',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Help others stay safe. Your details will be hidden.',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                  value: _isPublic,
                  activeColor: AppColors.accentGreen,
                  onChanged: (val) => setState(() => _isPublic = val),
               ),
             ),
             const SizedBox(height: 32),

             // ── Submit Button ────────────────────────────
              SizedBox(
                width: double.infinity,
                child: AdaptiveButton(
                  text: 'Submit Report',
                  isLoading: _isSubmitting,
                  onPressed: _submitReport,
                ),
              ),
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                   color: AppColors.accentGreen.withOpacity(0.1),
                   shape: BoxShape.circle,
                 ),
                 child: const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 80),
              ),
              const SizedBox(height: 32),
              const Text(
                'Report Submitted!',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Thank you for keeping the community safe. We will verify your report shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                child: AdaptiveButton(
                  text: 'Return Home',
                  onPressed: _resetForm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.primaryBlue,
        fontWeight: FontWeight.bold,
        fontSize: 14,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _DropdownButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DropdownButton({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
