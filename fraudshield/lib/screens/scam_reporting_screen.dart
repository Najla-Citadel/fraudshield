import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../widgets/selection_sheet.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/components/app_button.dart';
import '../widgets/adaptive_text_field.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/glass_surface.dart';
import '../l10n/app_localizations.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/components/app_snackbar.dart';

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
  double? _selectedLat;
  double? _selectedLng;

  final Map<String, Map<String, double>> _malaysiaStates = {
    'Johor': {'lat': 1.4854, 'lng': 103.7618},
    'Kedah': {'lat': 6.1184, 'lng': 100.3686},
    'Kelantan': {'lat': 6.1254, 'lng': 102.2381},
    'Melaka': {'lat': 2.1896, 'lng': 102.2501},
    'Negeri Sembilan': {'lat': 2.7258, 'lng': 101.9424},
    'Pahang': {'lat': 3.8126, 'lng': 103.3256},
    'Penang': {'lat': 5.4141, 'lng': 100.3288},
    'Perak': {'lat': 4.5921, 'lng': 101.0901},
    'Perlis': {'lat': 6.4449, 'lng': 100.2048},
    'Sabah': {'lat': 5.9788, 'lng': 116.0753},
    'Sarawak': {'lat': 1.5533, 'lng': 110.3592},
    'Selangor': {'lat': 3.0738, 'lng': 101.5183},
    'Terengganu': {'lat': 5.3117, 'lng': 103.1324},
    'Kuala Lumpur': {'lat': 3.1390, 'lng': 101.6869},
    'Labuan': {'lat': 5.2831, 'lng': 115.2443},
    'Putrajaya': {'lat': 2.9264, 'lng': 101.6964},
  };

  final List<Map<String, dynamic>> _targetTypeOptions = [
    {
      'id': 'Phone',
      'label': 'Phone Number',
      'icon': LucideIcons.phone,
      'desc': 'Calls or SMS'
    },
    {
      'id': 'Bank',
      'label': 'Bank Account',
      'icon': LucideIcons.landmark,
      'desc': 'Transfer details'
    },
    {
      'id': 'Social',
      'label': 'Social Media',
      'icon': LucideIcons.atSign,
      'desc': 'Handles / Profiles'
    },
    {
      'id': 'Web',
      'label': 'Website / App',
      'icon': LucideIcons.globe,
      'desc': 'Links or Apps'
    },
    {
      'id': 'Others',
      'label': 'Others',
      'icon': LucideIcons.moreHorizontal,
      'desc': 'General reports'
    },
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
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
      if (_targetType == 'Social' &&
          _socialHandleController.text.trim().isEmpty) {
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
    AppSnackBar.showError(context, msg);
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
          _locationController.text =
              '${p.street}, ${p.subLocality}, ${p.locality}';
        });
      }
    } catch (e) {
      log('Error reverse geocoding: $e');
    }
  }

  Future<void> _showLocationPicker() async {
    final selectedState = await SelectionSheet.show<String>(
      context: context,
      title: 'Select State',
      options: _malaysiaStates.keys.toList()..sort(),
      labelBuilder: (s) => s,
    );

    if (selectedState != null) {
      final coords = _malaysiaStates[selectedState]!;
      final targetLat = coords['lat']!;
      final targetLng = coords['lng']!;

      // Distance Check logic
      bool proceed = true;
      try {
        final position = await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 5),
            );

        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          targetLat,
          targetLng,
        );

        if (distance > 100000) {
          // > 100km
          if (mounted) {
            proceed = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                    backgroundColor: DesignTokens.colors.backgroundDark,
                    title: Text('Confirm Location',
                        style: TextStyle(color: DesignTokens.colors.textLight)),
                    content: Text(
                        'The selected state ($selectedState) is far from your current location. Are you sure you want to report for this area?',
                        style: TextStyle(color: DesignTokens.colors.textLight.withValues(alpha: 0.7))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel', style: TextStyle(color: DesignTokens.colors.textLight.withValues(alpha: 0.5)))),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Yes, Correct',
                              style: TextStyle(color: DesignTokens.colors.accentGreen))),
                    ],
                  );
                },
              ) ??
                false;
          }
        }
      } catch (e) {
        log('Distance check non-fatal error: $e');
      }

      if (proceed && mounted) {
        setState(() {
          _locationController.text = selectedState;
          _selectedLat = targetLat;
          _selectedLng = targetLng;
        });
      }
    }
  }

  Future<void> _submitReport() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isSubmitting = true);

    String? uploadedUrl;
    if (_selectedFilePath != null) {
      try {
        final uploadRes =
            await ApiService.instance.uploadFile(_selectedFilePath!);
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
      double? latitude = _selectedLat ?? widget.prefilledLat;
      double? longitude = _selectedLng ?? widget.prefilledLng;
      final manualLocation = _locationController.text.trim();

      if (latitude == null || longitude == null) {
        if (manualLocation.isNotEmpty) {
          try {
            final locations = await geo.locationFromAddress(manualLocation);
            if (locations.isNotEmpty) {
              latitude = locations.first.latitude;
              longitude = locations.first.longitude;
            }
          } catch (e) {
            log('Geocoding failed: $e');
          }
        }

        // Try getting last known position first (fast)
        if (latitude == null || longitude == null) {
          try {
            final lastPos = await Geolocator.getLastKnownPosition();
            if (lastPos != null) {
              latitude = lastPos.latitude;
              longitude = lastPos.longitude;
            }
          } catch (e) {
            log('Last known position failed: $e');
          }
        }

        // Fresh position as final fallback (slower)
        if (latitude == null || longitude == null) {
          try {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 10),
            );
            latitude = position.latitude;
            longitude = position.longitude;
          } catch (e) {
            log('GPS failed: $e');
          }
        }
      }

      // Consolidate 'target' based on type
      String targetVal = '';
      if (_targetType == 'Phone') {
        targetVal = _phoneController.text.trim();
      } else if (_targetType == 'Bank') {
        targetVal =
            '${_bankNameController.text.trim()} - ${_bankAccountController.text.trim()}';
      } else if (_targetType == 'Social') {
        targetVal =
            '${_socialPlatformController.text.trim()}: ${_socialHandleController.text.trim()}';
      } else if (_targetType == 'Web') {
        targetVal = _websiteUrlController.text.trim();
      } else {
        targetVal = 'General Report';
      }

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
          if (_targetType == 'Social') ...{
            'platform': _socialPlatformController.text.trim(),
            'handle': _socialHandleController.text.trim(),
          },
          if (_targetType == 'Web') 'url': _websiteUrlController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    if (_reportSent) return _buildSuccessScreen();

    return ScreenScaffold(
      title: AppLocalizations.of(context)!.scamReportTitle,
      bottomNavigationBar: _buildBottomNav(),
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
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final colors = DesignTokens.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isActive = index <= _currentStep;
              return Expanded(
                child: Container(
                  height: 3,
                  margin:
                      EdgeInsets.only(right: index == _totalSteps - 1 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? DesignTokens.colors.primary
                        : colors.textLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color:
                                  DesignTokens.colors.primary.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ]
                        : null,
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
                  style: TextStyle(
                      color: colors.textLight.withValues(alpha: 0.5),
                      fontSize: 12)),
              Text(_getStepTitle(),
                  style: TextStyle(
                      color: colors.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return AppLocalizations.of(context)!.reportStepIdentity;
      case 1:
        return AppLocalizations.of(context)!.reportStepCategory;
      case 2:
        return AppLocalizations.of(context)!.reportStepStory;
      case 3:
        return AppLocalizations.of(context)!.reportStepReview;
      default:
        return '';
    }
  }

  Widget _buildStep1Identity() {
    final colors = DesignTokens.colors;
    return AnimationLimiter(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 30.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            Text(AppLocalizations.of(context)!.reportIdentityTitle,
                style: DesignTypography.h3),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.reportIdentityDesc,
                style: TextStyle(
                    color: colors.textLight.withValues(alpha: 0.6), fontSize: 14)),
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
                return GlassSurface(
                  onTap: () => setState(() => _targetType = opt['id']),
                  padding: const EdgeInsets.all(12),
                  borderRadius: 20,
                  accentColor: isSelected ? DesignTokens.colors.primary : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(opt['icon'],
                          color: isSelected
                              ? DesignTokens.colors.primary
                              : Colors.white24),
                      const SizedBox(height: 10),
                      Text(opt['label'],
                          style: TextStyle(
                            color: isSelected
                                ? colors.textLight
                                : colors.textLight.withValues(alpha: 0.5),
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          )),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            _buildIdentityFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityFields() {
    final colors = DesignTokens.colors;
    if (_targetType == 'Phone') {
      return AdaptiveTextField(
        controller: _phoneController,
        label: 'Scammer Phone Number',
        keyboardType: TextInputType.phone,
        prefixIcon: LucideIcons.phone,
        filled: true,
        fillColor: colors.textLight.withValues(alpha: 0.05),
        textColor: colors.textLight,
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
            fillColor: colors.textLight.withValues(alpha: 0.05),
            textColor: colors.textLight,
          ),
          const SizedBox(height: 16),
          AdaptiveTextField(
            controller: _bankAccountController,
            label: 'Account Number',
            keyboardType: TextInputType.number,
            prefixIcon: LucideIcons.creditCard,
            filled: true,
            fillColor: colors.textLight.withValues(alpha: 0.05),
            textColor: colors.textLight,
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
            fillColor: colors.textLight.withValues(alpha: 0.05),
            textColor: colors.textLight,
          ),
          const SizedBox(height: 16),
          AdaptiveTextField(
            controller: _socialHandleController,
            label: 'Handle / Username',
            prefixIcon: LucideIcons.atSign,
            filled: true,
            fillColor: colors.textLight.withValues(alpha: 0.05),
            textColor: colors.textLight,
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
        fillColor: colors.textLight.withValues(alpha: 0.05),
        textColor: colors.textLight,
      );
    }
    return const SizedBox();
  }

  Widget _buildStep2Category() {
    final colors = DesignTokens.colors;
    final categories = [
      {
        'label': 'Investment Scam',
        'icon': LucideIcons.trendingUp,
        'color': Colors.amber
      },
      {
        'label': 'Phishing Scam',
        'icon': LucideIcons.shieldAlert,
        'color': Colors.red
      },
      {
        'label': 'Job Scam',
        'icon': LucideIcons.briefcase,
        'color': Colors.blue
      },
      {'label': 'Love Scam', 'icon': LucideIcons.heart, 'color': Colors.pink},
      {
        'label': 'Shopping Scam',
        'icon': LucideIcons.shoppingBag,
        'color': Colors.orange
      },
      {
        'label': 'Others',
        'icon': LucideIcons.moreHorizontal,
        'color': Colors.grey
      },
    ];

    return AnimationLimiter(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 30.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            Text('Select Category',
                style: DesignTypography.h3),
            const SizedBox(height: 24),
            ...categories.map((cat) {
              final isSelected = _selectedCategory == cat['label'];
              final color = cat['color'] as Color;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassSurface(
                  onTap: () => setState(
                      () => _selectedCategory = cat['label'] as String),
                  padding: const EdgeInsets.all(18),
                  borderRadius: 20,
                  accentColor: isSelected ? color : null,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat['icon'] as IconData,
                            color: color, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Text(cat['label'] as String,
                          style: TextStyle(
                              color: colors.textLight,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (isSelected)
                        Icon(LucideIcons.checkCircle2, color: color, size: 20),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3Details() {
    final colors = DesignTokens.colors;
    return AnimationLimiter(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 30.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            Text('Tell us the story',
                style: DesignTypography.h3),
            const SizedBox(height: 24),
            AdaptiveTextField(
              controller: _descController,
              label: 'Describe what happened...',
              maxLines: 5,
              filled: true,
              fillColor: colors.textLight.withValues(alpha: 0.05),
              textColor: colors.textLight,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _showLocationPicker,
              child: AbsorbPointer(
                child: AdaptiveTextField(
                  controller: _locationController,
                  label: 'State in Malaysia',
                  placeholder: 'Tap to select state',
                  prefixIcon: LucideIcons.mapPin,
                  filled: true,
                  fillColor: colors.textLight.withValues(alpha: 0.05),
                  textColor: colors.textLight,
                  suffixIcon: LucideIcons.chevronDown,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildFileUpload(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUpload() {
    final colors = DesignTokens.colors;
    return GlassSurface(
      onTap: _pickFile,
      padding: const EdgeInsets.all(32),
      borderRadius: 24,
      accentColor: _selectedFileName != null ? DesignTokens.colors.accentGreen : null,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (_selectedFileName != null
                      ? DesignTokens.colors.accentGreen
                      : Colors.white)
                  .withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedFileName != null
                  ? LucideIcons.checkCircle
                  : LucideIcons.uploadCloud,
              color: _selectedFileName != null
                  ? colors.accentGreen
                  : colors.textLight.withValues(alpha: 0.38),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFileName ?? 'Upload Screenshot or Evidence',
            style: TextStyle(
              color: _selectedFileName != null
                  ? colors.accentGreen
                  : colors.textLight.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (_selectedFileName == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('JPG, PNG or PDF (Max 5MB)',
                  style: TextStyle(
                      color: colors.textLight.withValues(alpha: 0.2),
                      fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _buildStep4Review() {
    final colors = DesignTokens.colors;
    return AnimationLimiter(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 30.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            Text('Final Review',
                style: DesignTypography.h3),
            const SizedBox(height: 24),
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DesignTokens.colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: DesignTokens.colors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This report will be analyzed by our AI system and shared with the community.',
                        style: TextStyle(
                            color: DesignTokens.colors.primary.withValues(alpha: 0.8),
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            _buildReviewCard(),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DesignTokens.colors.primary.withValues(alpha: 0.15),
                      DesignTokens.colors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
                  border: Border.all(
                    color: DesignTokens.colors.primary.withValues(alpha: 0.2),
                  ),
                ),
              child: SwitchListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text('Share with Community',
                    style: TextStyle(
                        color: colors.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                subtitle: Text('Hide your identity while helping others.',
                    style: TextStyle(
                        color: colors.textLight.withValues(alpha: 0.5),
                        fontSize: 12)),
                value: _isPublic,
                activeThumbColor: DesignTokens.colors.success,
                onChanged: (val) => setState(() => _isPublic = val),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard() {
    final colors = DesignTokens.colors;
    return GlassSurface(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      accentColor: DesignTokens.colors.primary,
      child: Column(
        children: [
          _ReviewItem(label: 'Identity', value: _targetType),
          const SizedBox(height: 4),
          _ReviewItem(label: 'Category', value: _selectedCategory),
          const SizedBox(height: 4),
          _ReviewItem(
              label: 'Target',
              value: _phoneController.text.isNotEmpty
                  ? _phoneController.text
                  : 'Multiple details'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: colors.textLight.withValues(alpha: 0.1)),
          ),
          _ReviewItem(label: 'Evidence', value: _selectedFileName ?? 'None'),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final colors = DesignTokens.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: TextButton(
                onPressed: _prevStep,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radii.sm)),
                ),
                child: Text('Back',
                    style: TextStyle(
                        color: colors.textLight.withValues(alpha: 0.7), fontWeight: FontWeight.bold)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: AppButton(
              label: _currentStep == _totalSteps - 1
                  ? AppLocalizations.of(context)!.reportSubmit
                  : AppLocalizations.of(context)!.btnNext,
              isLoading: _isSubmitting,
              onPressed:
                  _currentStep == _totalSteps - 1 ? _submitReport : _nextStep,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final colors = DesignTokens.colors;
    return ScreenScaffold(
      showBackButton: false,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: DesignTokens.colors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.checkCircle,
                    color: DesignTokens.colors.success, size: 80),
              ),
              const SizedBox(height: 32),
              Text(AppLocalizations.of(context)!.reportSubmitted,
                  style: DesignTypography.h2),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context)!.reportSuccessDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: colors.textLight.withValues(alpha: 0.7),
                      fontSize: 15,
                      height: 1.5)),
              const SizedBox(height: 48),
              SizedBox(
                width: 220,
                child: AppButton(
                  onPressed: () => Navigator.pop(context),
                  label: 'OK',
                  variant: AppButtonVariant.primary,
                  width: double.infinity,
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
