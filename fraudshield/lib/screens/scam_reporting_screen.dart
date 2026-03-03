import 'dart:developer';
import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
>>>>>>> dev-ui2
import 'package:file_picker/file_picker.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import 'report_history_screen.dart';
import '../widgets/selection_sheet.dart';
<<<<<<< HEAD
import '../widgets/adaptive_scaffold.dart';
=======
>>>>>>> dev-ui2
import '../widgets/adaptive_button.dart';
import '../widgets/adaptive_text_field.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:lucide_icons/lucide_icons.dart';
<<<<<<< HEAD
=======
import '../l10n/app_localizations.dart';
>>>>>>> dev-ui2

class ScamReportingScreen extends StatefulWidget {
  final double? prefilledLat;
  final double? prefilledLng;

  const ScamReportingScreen({
<<<<<<< HEAD
    super.key, 
    this.prefilledLat, 
=======
    super.key,
    this.prefilledLat,
>>>>>>> dev-ui2
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
<<<<<<< HEAD

  final List<Map<String, dynamic>> _targetTypeOptions = [
    {'id': 'Phone', 'label': 'Phone Number', 'icon': LucideIcons.phone, 'desc': 'Calls or SMS'},
    {'id': 'Bank', 'label': 'Bank Account', 'icon': LucideIcons.landmark, 'desc': 'Transfer details'},
    {'id': 'Social', 'label': 'Social Media', 'icon': LucideIcons.atSign, 'desc': 'Handles / Profiles'},
    {'id': 'Web', 'label': 'Website / App', 'icon': LucideIcons.globe, 'desc': 'Links or Apps'},
    {'id': 'Others', 'label': 'Others', 'icon': LucideIcons.moreHorizontal, 'desc': 'General reports'},
=======
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
>>>>>>> dev-ui2
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
<<<<<<< HEAD
      _pageController.animateToPage(
        _currentStep, 
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOut
      );
=======
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
>>>>>>> dev-ui2
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
<<<<<<< HEAD
      _pageController.animateToPage(
        _currentStep, 
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOut
      );
=======
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
>>>>>>> dev-ui2
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
<<<<<<< HEAD
      if (_targetType == 'Social' && _socialHandleController.text.trim().isEmpty) {
=======
      if (_targetType == 'Social' &&
          _socialHandleController.text.trim().isEmpty) {
>>>>>>> dev-ui2
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
<<<<<<< HEAD
          _locationController.text = '${p.street}, ${p.subLocality}, ${p.locality}';
=======
          _locationController.text =
              '${p.street}, ${p.subLocality}, ${p.locality}';
>>>>>>> dev-ui2
        });
      }
    } catch (e) {
      log('Error reverse geocoding: $e');
    }
  }

<<<<<<< HEAD
  Future<void> _submitReport() async {
    if (!_validateCurrentStep()) return;
    
=======
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
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.deepNavy,
                    title: const Text('Confirm Location',
                        style: TextStyle(color: Colors.white)),
                    content: Text(
                        'The selected state ($selectedState) is far from your current location. Are you sure you want to report for this area?',
                        style: const TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Yes, Correct',
                              style: TextStyle(color: AppColors.accentGreen))),
                    ],
                  ),
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

>>>>>>> dev-ui2
    setState(() => _isSubmitting = true);

    String? uploadedUrl;
    if (_selectedFilePath != null) {
      try {
<<<<<<< HEAD
        final uploadRes = await ApiService.instance.uploadFile(_selectedFilePath!);
=======
        final uploadRes =
            await ApiService.instance.uploadFile(_selectedFilePath!);
>>>>>>> dev-ui2
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
<<<<<<< HEAD
      double? latitude = widget.prefilledLat;
      double? longitude = widget.prefilledLng;
      final manualLocation = _locationController.text.trim();
      
=======
      double? latitude = _selectedLat ?? widget.prefilledLat;
      double? longitude = _selectedLng ?? widget.prefilledLng;
      final manualLocation = _locationController.text.trim();

>>>>>>> dev-ui2
      if (latitude == null || longitude == null) {
        if (manualLocation.isNotEmpty) {
          try {
            final locations = await geo.locationFromAddress(manualLocation);
            if (locations.isNotEmpty) {
              latitude = locations.first.latitude;
              longitude = locations.first.longitude;
            }
<<<<<<< HEAD
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
=======
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
>>>>>>> dev-ui2
        }
      }

      // Consolidate 'target' based on type
      String targetVal = '';
<<<<<<< HEAD
      if (_targetType == 'Phone') targetVal = _phoneController.text.trim();
      else if (_targetType == 'Bank') targetVal = '${_bankNameController.text.trim()} - ${_bankAccountController.text.trim()}';
      else if (_targetType == 'Social') targetVal = '${_socialPlatformController.text.trim()}: ${_socialHandleController.text.trim()}';
      else if (_targetType == 'Web') targetVal = _websiteUrlController.text.trim();
      else targetVal = 'General Report';
=======
      if (_targetType == 'Phone')
        targetVal = _phoneController.text.trim();
      else if (_targetType == 'Bank')
        targetVal =
            '${_bankNameController.text.trim()} - ${_bankAccountController.text.trim()}';
      else if (_targetType == 'Social')
        targetVal =
            '${_socialPlatformController.text.trim()}: ${_socialHandleController.text.trim()}';
      else if (_targetType == 'Web')
        targetVal = _websiteUrlController.text.trim();
      else
        targetVal = 'General Report';
>>>>>>> dev-ui2

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
<<<<<<< HEAD
=======
          if (_targetType == 'Social') ...{
            'platform': _socialPlatformController.text.trim(),
            'handle': _socialHandleController.text.trim(),
          },
          if (_targetType == 'Web') 'url': _websiteUrlController.text.trim(),
>>>>>>> dev-ui2
          if (uploadedUrl != null) 'evidence_url': uploadedUrl,
          'location_text': _locationController.text.trim(),
        },
      );
<<<<<<< HEAD
      
=======

>>>>>>> dev-ui2
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

<<<<<<< HEAD
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

=======
>>>>>>> dev-ui2
  @override
  Widget build(BuildContext context) {
    if (_reportSent) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
<<<<<<< HEAD
      appBar: AppBar(
        title: const Text('Report Scam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
=======
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.scamReportTitle,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
>>>>>>> dev-ui2
            tooltip: 'Report History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportHistoryScreen()),
            ),
          ),
        ],
      ),
<<<<<<< HEAD
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
=======
      body: Stack(
        children: [
          // Background Depth
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F172A), // Slate 900
                  AppColors.deepNavy, // Deep navy
                  Color(0xFF1E3A8A), // Blue 900
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
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
        ],
>>>>>>> dev-ui2
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
<<<<<<< HEAD
                  height: 4,
                  margin: EdgeInsets.only(right: index == _totalSteps - 1 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryBlue : Colors.white10,
                    borderRadius: BorderRadius.circular(2),
=======
                  height: 3,
                  margin:
                      EdgeInsets.only(right: index == _totalSteps - 1 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.accentGreen
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.accentGreen.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ]
                        : null,
>>>>>>> dev-ui2
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
<<<<<<< HEAD
              Text('Step ${_currentStep + 1} of $_totalSteps', 
                style: TextStyle(color: Colors.white60, fontSize: 12)),
              Text(_getStepTitle(), 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
=======
              Text('Step ${_currentStep + 1} of $_totalSteps',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12)),
              Text(_getStepTitle(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
>>>>>>> dev-ui2
            ],
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
<<<<<<< HEAD
      case 0: return 'Scammer Identity';
      case 1: return 'Scam Category';
      case 2: return 'The Story';
      case 3: return 'Review & Submit';
      default: return '';
=======
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
>>>>>>> dev-ui2
    }
  }

  Widget _buildStep1Identity() {
<<<<<<< HEAD
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('What information do you have?', 
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Select the main identifier for the scammer.', 
          style: TextStyle(color: Colors.white60, fontSize: 14)),
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
                  color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryBlue : Colors.white.withOpacity(0.05),
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
=======
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
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.reportIdentityDesc,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
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
                      color: isSelected
                          ? AppColors.primaryBlue.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : Colors.white.withValues(alpha: 0.08),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(opt['icon'],
                            color: isSelected
                                ? AppColors.primaryBlue
                                : Colors.white24,
                            size: 28),
                        const SizedBox(height: 10),
                        Text(opt['label'],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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
        ),
      ),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
        fillColor: const Color(0xFF1E293B),
=======
        fillColor: Colors.white.withValues(alpha: 0.05),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
            fillColor: const Color(0xFF1E293B),
=======
            fillColor: Colors.white.withValues(alpha: 0.05),
>>>>>>> dev-ui2
            textColor: Colors.white,
          ),
          const SizedBox(height: 16),
          AdaptiveTextField(
            controller: _bankAccountController,
            label: 'Account Number',
            keyboardType: TextInputType.number,
            prefixIcon: LucideIcons.creditCard,
            filled: true,
<<<<<<< HEAD
            fillColor: const Color(0xFF1E293B),
=======
            fillColor: Colors.white.withValues(alpha: 0.05),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
            fillColor: const Color(0xFF1E293B),
=======
            fillColor: Colors.white.withValues(alpha: 0.05),
>>>>>>> dev-ui2
            textColor: Colors.white,
          ),
          const SizedBox(height: 16),
          AdaptiveTextField(
            controller: _socialHandleController,
            label: 'Handle / Username',
            prefixIcon: LucideIcons.atSign,
            filled: true,
<<<<<<< HEAD
            fillColor: const Color(0xFF1E293B),
=======
            fillColor: Colors.white.withValues(alpha: 0.05),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
        fillColor: const Color(0xFF1E293B),
=======
        fillColor: Colors.white.withValues(alpha: 0.05),
>>>>>>> dev-ui2
        textColor: Colors.white,
      );
    }
    return const SizedBox();
  }

  Widget _buildStep2Category() {
    final categories = [
<<<<<<< HEAD
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
                color: isSelected ? (cat['color'] as Color).withOpacity(0.1) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? (cat['color'] as Color) : Colors.white.withOpacity(0.05),
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
=======
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
            const Text('Select Category',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ...categories.map((cat) {
              final isSelected = _selectedCategory == cat['label'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedCategory = cat['label'] as String),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (cat['color'] as Color).withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? (cat['color'] as Color)
                          : Colors.white.withValues(alpha: 0.08),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (cat['color'] as Color).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat['icon'] as IconData,
                            color: cat['color'] as Color, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Text(cat['label'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (isSelected)
                        Icon(LucideIcons.checkCircle2,
                            color: cat['color'] as Color, size: 20),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
>>>>>>> dev-ui2
    );
  }

  Widget _buildStep3Details() {
<<<<<<< HEAD
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
=======
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
            const Text('Tell us the story',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            AdaptiveTextField(
              controller: _descController,
              label: 'Describe what happened...',
              maxLines: 5,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              textColor: Colors.white,
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
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  textColor: Colors.white,
                  suffixIcon: LucideIcons.chevronDown,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildFileUpload(),
          ],
        ),
      ),
>>>>>>> dev-ui2
    );
  }

  Widget _buildFileUpload() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
<<<<<<< HEAD
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedFileName != null ? AppColors.accentGreen : Colors.white.withOpacity(0.1),
            style: BorderStyle.solid,
=======
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _selectedFileName != null
                ? AppColors.accentGreen
                : Colors.white.withValues(alpha: 0.1),
            style: BorderStyle.solid,
            width: 1.5,
>>>>>>> dev-ui2
          ),
        ),
        child: Column(
          children: [
<<<<<<< HEAD
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
=======
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_selectedFileName != null
                        ? AppColors.accentGreen
                        : Colors.white)
                    .withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _selectedFileName != null
                    ? LucideIcons.checkCircle
                    : LucideIcons.uploadCloud,
                color: _selectedFileName != null
                    ? AppColors.accentGreen
                    : Colors.white38,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFileName ?? 'Upload Screenshot or Evidence',
              style: TextStyle(
                color: _selectedFileName != null
                    ? AppColors.accentGreen
                    : Colors.white70,
>>>>>>> dev-ui2
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedFileName == null)
<<<<<<< HEAD
              Text('JPG, PNG or PDF (Max 5MB)', 
                style: TextStyle(color: Colors.white24, fontSize: 11)),
=======
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('JPG, PNG or PDF (Max 5MB)',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 11)),
              ),
>>>>>>> dev-ui2
          ],
        ),
      ),
    );
  }

  Widget _buildStep4Review() {
<<<<<<< HEAD
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
=======
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
            const Text('Final Review',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildReviewCard(),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: SwitchListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: const Text('Share with Community',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                subtitle: Text('Hide your identity while helping others.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12)),
                value: _isPublic,
                activeColor: AppColors.accentGreen,
                onChanged: (val) => setState(() => _isPublic = val),
              ),
            ),
          ],
        ),
      ),
>>>>>>> dev-ui2
    );
  }

  Widget _buildReviewCard() {
    return Container(
<<<<<<< HEAD
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
=======
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
>>>>>>> dev-ui2
      ),
      child: Column(
        children: [
          _ReviewItem(label: 'Identity', value: _targetType),
<<<<<<< HEAD
          _ReviewItem(label: 'Category', value: _selectedCategory),
          _ReviewItem(label: 'Target', value: _phoneController.text.isNotEmpty ? _phoneController.text : 'Multiple details'),
          const Divider(color: Colors.white10),
=======
          const SizedBox(height: 4),
          _ReviewItem(label: 'Category', value: _selectedCategory),
          const SizedBox(height: 4),
          _ReviewItem(
              label: 'Target',
              value: _phoneController.text.isNotEmpty
                  ? _phoneController.text
                  : 'Multiple details'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white10),
          ),
>>>>>>> dev-ui2
          _ReviewItem(label: 'Evidence', value: _selectedFileName ?? 'None'),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
<<<<<<< HEAD
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.deepNavy,
        border: Border(top: BorderSide(color: Colors.white10)),
=======
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
>>>>>>> dev-ui2
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: TextButton(
                onPressed: _prevStep,
<<<<<<< HEAD
                child: const Text('Back', style: TextStyle(color: Colors.white70)),
=======
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back',
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.bold)),
>>>>>>> dev-ui2
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: AdaptiveButton(
<<<<<<< HEAD
              text: _currentStep == _totalSteps - 1 ? 'Submit Report' : 'Continue',
              isLoading: _isSubmitting,
              onPressed: _currentStep == _totalSteps - 1 ? _submitReport : _nextStep,
=======
              text: _currentStep == _totalSteps - 1
                  ? AppLocalizations.of(context)!.reportSubmit
                  : AppLocalizations.of(context)!.btnNext,
              isLoading: _isSubmitting,
              onPressed:
                  _currentStep == _totalSteps - 1 ? _submitReport : _nextStep,
>>>>>>> dev-ui2
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
<<<<<<< HEAD
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
                 child: const Icon(LucideIcons.checkCircle, color: AppColors.accentGreen, size: 80),
              ),
              const SizedBox(height: 32),
              const Text('Report Submitted!', 
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Thank you for keeping the community safe. We will verify your report shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.5)),
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
=======
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F172A),
                  AppColors.deepNavy,
                  Color(0xFF1E3A8A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Center(
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
                    child: const Icon(LucideIcons.checkCircle,
                        color: AppColors.accentGreen, size: 80),
                  ),
                  const SizedBox(height: 32),
                  Text(AppLocalizations.of(context)!.reportSubmitted,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(AppLocalizations.of(context)!.reportSuccessDesc,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 15,
                          height: 1.5)),
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
        ],
>>>>>>> dev-ui2
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
<<<<<<< HEAD
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
=======
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
>>>>>>> dev-ui2
        ],
      ),
    );
  }
}
<<<<<<< HEAD

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
=======
>>>>>>> dev-ui2
