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
import 'package:lucide_icons/lucide_icons.dart';
import '../l10n/app_localizations.dart';

class ScamReportingScreen extends StatefulWidget {
  final double? prefilledLat;
  final double? prefilledLng;

  const ScamReportingScreen({
    super.key, 
    this.prefilledLat, 
    this.prefilledLng,
  });

  @override
  State<ScamReportingScreen> createState() => _ScamReportingScreenState();
}

class _ScamReportingScreenState extends State<ScamReportingScreen> {
  // --- Wizard State ---
  int _currentStep = 0;
  final int _totalSteps = 4;
  final PageController _pageController = PageController();

  // --- Step 1: Identity Data ---
  String _targetType = 'Phone'; // Phone, Bank, Social, Web, Others
  final _phoneController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _socialPlatformController = TextEditingController();
  final _socialHandleController = TextEditingController();
  final _websiteUrlController = TextEditingController();

  // --- Step 2: Category ---
  String _selectedCategory = 'Investment Scam';

  // --- Step 3: Story & Evidence ---
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedFilePath;
  String? _selectedFileName;

  // --- Step 4: Finalize ---
  bool _isPublic = true;
  bool _isSubmitting = false;
  bool _reportSent = false;

  final List<Map<String, dynamic>> _targetTypeOptions = [
    {'id': 'Phone', 'label': 'Phone Number', 'icon': LucideIcons.phone, 'desc': 'Calls or SMS'},
    {'id': 'Bank', 'label': 'Bank Account', 'icon': LucideIcons.landmark, 'desc': 'Transfer details'},
    {'id': 'Social', 'label': 'Social Media', 'icon': LucideIcons.atSign, 'desc': 'Handles / Profiles'},
    {'id': 'Web', 'label': 'Website / App', 'icon': LucideIcons.globe, 'desc': 'Links or Apps'},
    {'id': 'Others', 'label': 'Others', 'icon': LucideIcons.moreHorizontal, 'desc': 'General reports'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.prefilledLat != null && widget.prefilledLng != null) {
      _fetchAddressFromCoords(widget.prefilledLat!, widget.prefilledLng!);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _socialPlatformController.dispose();
    _socialHandleController.dispose();
    _websiteUrlController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      if (!_validateCurrentStep()) return;
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep, 
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOut
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep, 
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOut
      );
    }
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_targetType == 'Phone' && _phoneController.text.trim().isEmpty) {
        _showError('Please enter the scammer\'s phone number');
        return false;
      }
      if (_targetType == 'Bank') {
        if (_bankNameController.text.trim().isEmpty) {
          _showError('Please enter the bank name');
          return false;
        }
        if (_bankAccountController.text.trim().isEmpty) {
          _showError('Please enter the account number');
          return false;
        }
      }
      if (_targetType == 'Social' && _socialHandleController.text.trim().isEmpty) {
        _showError('Please enter the social media handle');
        return false;
      }
      if (_targetType == 'Web' && _websiteUrlController.text.trim().isEmpty) {
        _showError('Please enter the website URL');
        return false;
      }
    } else if (_currentStep == 2) {
      if (_descController.text.trim().length < 10) {
        _showError('Description must be at least 10 characters long');
        return false;
      }
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
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

  Future<void> _fetchAddressFromCoords(double lat, double lng) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        setState(() {
          _locationController.text = '${p.street}, ${p.subLocality}, ${p.locality}';
        });
      }
    } catch (e) {
      log('Error reverse geocoding: $e');
    }
  }

  Future<void> _submitReport() async {
    if (!_validateCurrentStep()) return;
    
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
          _showError('Failed to upload evidence: $e');
        }
        return;
      }
    }

    try {
      double? latitude = widget.prefilledLat;
      double? longitude = widget.prefilledLng;
      final manualLocation = _locationController.text.trim();
      
      if (latitude == null || longitude == null) {
        if (manualLocation.isNotEmpty) {
          try {
            final locations = await geo.locationFromAddress(manualLocation);
            if (locations.isNotEmpty) {
              latitude = locations.first.latitude;
              longitude = locations.first.longitude;
            }
          } catch (e) { log('Geocoding failed: $e'); }
        }
        if (latitude == null || longitude == null) {
          try {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 5),
            );
            latitude = position.latitude;
            longitude = position.longitude;
          } catch (e) { log('GPS failed: $e'); }
        }
      }

      // Consolidate 'target' based on type
      String targetVal = '';
      if (_targetType == 'Phone') targetVal = _phoneController.text.trim();
      else if (_targetType == 'Bank') targetVal = '${_bankNameController.text.trim()} - ${_bankAccountController.text.trim()}';
      else if (_targetType == 'Social') targetVal = '${_socialPlatformController.text.trim()}: ${_socialHandleController.text.trim()}';
      else if (_targetType == 'Web') targetVal = _websiteUrlController.text.trim();
      else targetVal = 'General Report';

      await ApiService.instance.submitScamReport(
        type: _targetType,
        category: _selectedCategory,
        description: _descController.text.trim(),
        target: targetVal,
        isPublic: _isPublic,
        latitude: latitude,
        longitude: longitude,
        evidence: {
          'target_type': _targetType,
          if (_targetType == 'Phone') 'phone': _phoneController.text.trim(),
          if (_targetType == 'Bank') ...{
            'bank_name': _bankNameController.text.trim(),
            'account_number': _bankAccountController.text.trim(),
          },
          if (uploadedUrl != null) 'evidence_url': uploadedUrl,
          'location_text': _locationController.text.trim(),
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
        _showError('Failed to submit report: $e');
      }
    }
  }

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _reportSent = false;
      _phoneController.clear();
      _bankNameController.clear();
      _bankAccountController.clear();
      _socialPlatformController.clear();
      _socialHandleController.clear();
      _websiteUrlController.clear();
      _descController.clear();
      _locationController.clear();
      _selectedFilePath = null;
      _selectedFileName = null;
      _isPublic = true;
    });
    _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_reportSent) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.scamReportTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Report History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportHistoryScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Identity(),
                  _buildStep2Category(),
                  _buildStep3Details(),
                  _buildStep4Review(),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isActive = index <= _currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index == _totalSteps - 1 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryBlue : Colors.white10,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step ${_currentStep + 1} of $_totalSteps', 
                style: TextStyle(color: Colors.white60, fontSize: 12)),
              Text(_getStepTitle(), 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return AppLocalizations.of(context)!.reportStepIdentity;
      case 1: return AppLocalizations.of(context)!.reportStepCategory;
      case 2: return AppLocalizations.of(context)!.reportStepStory;
      case 3: return AppLocalizations.of(context)!.reportStepReview;
      default: return '';
    }
  }

  Widget _buildStep1Identity() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(AppLocalizations.of(context)!.reportIdentityTitle, 
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(AppLocalizations.of(context)!.reportIdentityDesc, 
          style: const TextStyle(color: Colors.white60, fontSize: 14)),
        const SizedBox(height: 24),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: _targetTypeOptions.length,
          itemBuilder: (context, index) {
            final opt = _targetTypeOptions[index];
            final isSelected = _targetType == opt['id'];
            return GestureDetector(
              onTap: () => setState(() => _targetType = opt['id']),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.1) : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryBlue : Colors.white.withValues(alpha: 0.05),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(opt['icon'], color: isSelected ? AppColors.primaryBlue : Colors.white38, size: 28),
                    const SizedBox(height: 8),
                    Text(opt['label'], style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    )),
                  ],
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 32),
        _buildIdentityFields(),
      ],
    );
  }

  Widget _buildIdentityFields() {
    if (_targetType == 'Phone') {
      return AdaptiveTextField(
        controller: _phoneController,
        label: 'Scammer Phone Number',
        keyboardType: TextInputType.phone,
        prefixIcon: LucideIcons.phone,
        filled: true,
        fillColor: const Color(0xFF1E293B),
        textColor: Colors.white,
      );
    }
    if (_targetType == 'Bank') {
      return Column(
        children: [
          AdaptiveTextField(
            controller: _bankNameController,
            label: 'Bank Name',
            prefixIcon: LucideIcons.landmark,
            filled: true,
            fillColor: const Color(0xFF1E293B),
            textColor: Colors.white,
          ),
          const SizedBox(height: 16),
          AdaptiveTextField(
            controller: _bankAccountController,
            label: 'Account Number',
            keyboardType: TextInputType.number,
            prefixIcon: LucideIcons.creditCard,
            filled: true,
            fillColor: const Color(0xFF1E293B),
            textColor: Colors.white,
          ),
        ],
      );
    }
    if (_targetType == 'Social') {
      return Column(
        children: [
          AdaptiveTextField(
            controller: _socialPlatformController,
            label: 'Platform (e.g. FB, Telegram)',
            prefixIcon: LucideIcons.globe,
            filled: true,
            fillColor: const Color(0xFF1E293B),
            textColor: Colors.white,
          ),
          const SizedBox(height: 16),
          AdaptiveTextField(
            controller: _socialHandleController,
            label: 'Handle / Username',
            prefixIcon: LucideIcons.atSign,
            filled: true,
            fillColor: const Color(0xFF1E293B),
            textColor: Colors.white,
          ),
        ],
      );
    }
    if (_targetType == 'Web') {
      return AdaptiveTextField(
        controller: _websiteUrlController,
        label: 'Website URL / App Link',
        prefixIcon: LucideIcons.globe,
        filled: true,
        fillColor: const Color(0xFF1E293B),
        textColor: Colors.white,
      );
    }
    return const SizedBox();
  }

  Widget _buildStep2Category() {
    final categories = [
      {'label': 'Investment Scam', 'icon': LucideIcons.trendingUp, 'color': Colors.amber},
      {'label': 'Phishing Scam', 'icon': LucideIcons.shieldAlert, 'color': Colors.red},
      {'label': 'Job Scam', 'icon': LucideIcons.briefcase, 'color': Colors.blue},
      {'label': 'Love Scam', 'icon': LucideIcons.heart, 'color': Colors.pink},
      {'label': 'Shopping Scam', 'icon': LucideIcons.shoppingBag, 'color': Colors.orange},
      {'label': 'Others', 'icon': LucideIcons.moreHorizontal, 'color': Colors.grey},
    ];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Select Category', 
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ...categories.map((cat) {
          final isSelected = _selectedCategory == cat['label'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['label'] as String),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? (cat['color'] as Color).withValues(alpha: 0.1) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? (cat['color'] as Color) : Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                children: [
                  Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 24),
                  const SizedBox(width: 16),
                  Text(cat['label'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (isSelected) Icon(LucideIcons.checkCircle2, color: cat['color'] as Color, size: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStep3Details() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Tell us the story', 
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        AdaptiveTextField(
          controller: _descController,
          label: 'Describe what happened...',
          maxLines: 5,
          filled: true,
          fillColor: const Color(0xFF1E293B),
          textColor: Colors.white,
        ),
        const SizedBox(height: 24),
        AdaptiveTextField(
          controller: _locationController,
          label: 'City / State (Optional)',
          prefixIcon: LucideIcons.mapPin,
          filled: true,
          fillColor: const Color(0xFF1E293B),
          textColor: Colors.white,
        ),
        const SizedBox(height: 24),
        _buildFileUpload(),
      ],
    );
  }

  Widget _buildFileUpload() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedFileName != null ? AppColors.accentGreen : Colors.white.withValues(alpha: 0.1),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _selectedFileName != null ? LucideIcons.checkCircle : LucideIcons.uploadCloud,
              color: _selectedFileName != null ? AppColors.accentGreen : Colors.white38,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              _selectedFileName ?? 'Upload Screenshot or Evidence',
              style: TextStyle(
                color: _selectedFileName != null ? AppColors.accentGreen : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedFileName == null)
              Text('JPG, PNG or PDF (Max 5MB)', 
                style: TextStyle(color: Colors.white24, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4Review() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Final Review', 
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildReviewCard(),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SwitchListTile(
            title: const Text('Share with Community', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Hide your identity while helping others.', 
              style: TextStyle(color: Colors.white60, fontSize: 12)),
            value: _isPublic,
            activeColor: AppColors.accentGreen,
            onChanged: (val) => setState(() => _isPublic = val),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _ReviewItem(label: 'Identity', value: _targetType),
          _ReviewItem(label: 'Category', value: _selectedCategory),
          _ReviewItem(label: 'Target', value: _phoneController.text.isNotEmpty ? _phoneController.text : 'Multiple details'),
          const Divider(color: Colors.white10),
          _ReviewItem(label: 'Evidence', value: _selectedFileName ?? 'None'),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.deepNavy,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: TextButton(
                onPressed: _prevStep,
                child: const Text('Back', style: TextStyle(color: Colors.white70)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: AdaptiveButton(
              text: _currentStep == _totalSteps - 1 
                  ? AppLocalizations.of(context)!.reportSubmit 
                  : AppLocalizations.of(context)!.btnNext,
              isLoading: _isSubmitting,
              onPressed: _currentStep == _totalSteps - 1 ? _submitReport : _nextStep,
            ),
          ),
        ],
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
                   color: AppColors.accentGreen.withValues(alpha: 0.1),
                   shape: BoxShape.circle,
                 ),
                 child: const Icon(LucideIcons.checkCircle, color: AppColors.accentGreen, size: 80),
              ),
              const SizedBox(height: 32),
              Text(AppLocalizations.of(context)!.reportSubmitted, 
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context)!.reportSuccessDesc,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15, height: 1.5)),
              const SizedBox(height: 48),
              SizedBox(
                width: 220,
                child: AdaptiveButton(
                  text: 'Back to Community',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(
      color: AppColors.primaryBlue,
      fontWeight: FontWeight.bold,
      fontSize: 14,
      letterSpacing: 0.5,
    ));
  }
}
