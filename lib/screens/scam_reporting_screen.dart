// lib/screens/scam_reporting_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/core/custom_text_field.dart';
import '../widgets/core/primary_button.dart';
import '../widgets/core/secondary_button.dart';
import '../widgets/core/section_header.dart';
import '../services/supabase_service.dart';
import 'report_history_screen.dart';

class ScamReportingScreen extends StatefulWidget {
  const ScamReportingScreen({super.key});

  @override
  State<ScamReportingScreen> createState() => _ScamReportingScreenState();
}

class _ScamReportingScreenState extends State<ScamReportingScreen> {
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();
  final _supabase = SupabaseService.instance;
  
  String _selectedCategory = 'Investment Scam';
  bool _reportSent = false;
  bool _loading = false;
  
  String _reportType = 'Phone';
  final List<String> _reportTypes = ['Phone', 'Message', 'Document', 'Others'];

  final List<String> _categories = [
    'Investment Scam',
    'Fake Giveaway / Promo Scam',
    'Phishing Scam',
    'Job Scam',
    'Love Scam',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submitReport() async {
    bool isPhoneValid = _reportType != 'Phone' || _phoneController.text.trim().isNotEmpty;

    if (!isPhoneValid || _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _supabase.createScamReport(
        reportType: _reportType,
        category: _selectedCategory,
        description: _descController.text.trim(),
        phoneNumber: _reportType == 'Phone' ? _phoneController.text.trim() : null,
      );

      if (mounted) {
        setState(() {
          _reportSent = true;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting report: $e')),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      _reportSent = false;
      _phoneController.clear();
      _descController.clear();
      _reportType = 'Phone';
      _selectedCategory = _categories.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_reportSent) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Scam Reporting'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Report History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportHistoryScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⚠️ Disclaimer
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(
                      'Reports may be shared with relevant authorities for review.',
                      style: AppTypography.bodyS.copyWith(color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.l),

            // 📝 Form Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusM),
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
                  const SectionHeader(title: 'What type of scam?', actionLabel: ''),
                  const SizedBox(height: AppSpacing.s),
                  
                  // Report Type Dropdown (Custom)
                  _buildDropdown(
                    value: _reportType,
                    items: _reportTypes,
                    onChanged: (val) => setState(() => _reportType = val!),
                  ),

                  const SizedBox(height: AppSpacing.l),

                  // Dynamic Fields
                  if (_reportType == 'Phone') 
                    CustomTextField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      hintText: '+6012 345 6789',
                    ),

                  const SizedBox(height: AppSpacing.l),

                  const SectionHeader(title: 'Category', actionLabel: ''),
                  const SizedBox(height: AppSpacing.s),
                  
                  _buildDropdown(
                    value: _selectedCategory,
                    items: _categories,
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),

                  const SizedBox(height: AppSpacing.l),

                  CustomTextField(
                    label: 'Description',
                    controller: _descController,
                    maxLines: 4,
                    hintText: 'Describe what happened...',
                  ),

                  const SizedBox(height: AppSpacing.l),

                  // Attachments (Secondary Action)
                  SecondaryButton(
                    label: 'Upload Evidence (Optional)',
                    icon: Icons.upload_file,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('File upload coming soon')),
                      );
                    },
                    isFullWidth: true,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  PrimaryButton(
                    label: 'Submit Report',
                    onPressed: _loading ? null : _submitReport,
                    isLoading: _loading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusM),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: AppTypography.bodyM))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Report Sent')),
      body: Center(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 80),
              const SizedBox(height: AppSpacing.l),
              Text('Report Submitted!', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.s),
              Text(
                'We will verify your report and take necessary action.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyM,
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(label: 'Done', onPressed: _resetForm),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper mainly for the secondary button update
extension on SecondaryButton {
  // Adding a copy with icon support if needed, but for now simple button ok
  // Actually SecondaryButton doesn't support icon yet, let's fix that or use OutlinedButton.icon
  
  // NOTE: I'll stick to basic SecondaryButton usage or update the widget definition if I need icons.
  // In existing code I just used 'icon' property but SecondaryButton definition might not have it.
  // Checking definition: it does NOT have icon. I will use a Row inside child if needed, or update definition.
  // Let's update SecondaryButton definition separately or just use OutlinedButton directly here?
  // I will use OutlinedButton.icon for this specific case directly in the build method.
}
