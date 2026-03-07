import 'package:flutter/material.dart';
import '../design_system/components/app_loading_indicator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../widgets/scam_card.dart';
import '../widgets/glass_surface.dart';
import 'scam_report_entry_screen.dart';

class ScamMapScreen extends StatefulWidget {
  const ScamMapScreen({super.key});

  @override
  State<ScamMapScreen> createState() => _ScamMapScreenState();
}

class _ScamMapScreenState extends State<ScamMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<dynamic> _reports = [];
  bool _isLoading = true;
  String? _selectedCategory;
  LatLng? _lastSearchPosition;
  bool _showSearchThisArea = false;
  LatLng? _currentCameraPosition;

  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(3.1390, 101.6869), // Kuala Lumpur
    zoom: 12.0,
  );

  final List<String> _categories = [
    'All',
    'Phishing',
    'Investment',
    'E-Wallet',
    'Courier',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _fetchReports();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _getUserLocation();
    }
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() => _currentPosition = position);
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
        // Initial fetch around user
        _fetchReports(
            lat: position.latitude, lng: position.longitude, radius: 5.0);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _fetchReports({double? lat, double? lng, double? radius}) async {
    setState(() {
      _isLoading = true;
      _showSearchThisArea = false;
      if (lat != null && lng != null) {
        _lastSearchPosition = LatLng(lat, lng);
        _updateCircles(lat, lng, radius ?? 5.0);
      }
    });

    try {
      final response = await ApiService.instance.getPublicFeed(
        lat: lat,
        lng: lng,
        radius: radius,
      );
      if (mounted) {
        setState(() {
          _reports = response['results'] ?? [];
          _isLoading = false;
        });
        _updateMarkers();
      }
    } catch (e) {
      debugPrint('Error fetching reports: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateCircles(double lat, double lng, double radiusKm) {
    setState(() {
      _circles.clear();
      _circles.add(
        Circle(
          circleId: const CircleId('search_radius'),
          center: LatLng(lat, lng),
          radius: radiusKm * 1000,
          fillColor: DesignTokens.colors.accentGreen.withOpacity(0.05),
          strokeColor: DesignTokens.colors.accentGreen.withOpacity(0.2),
          strokeWidth: 1,
        ),
      );
    });
  }

  void _onCameraMove(CameraPosition position) {
    _currentCameraPosition = position.target;
  }

  void _onCameraIdle() {
    if (_lastSearchPosition == null || _currentCameraPosition == null) return;

    // Check if camera moved significantly (e.g. more than 1km)
    final distance = Geolocator.distanceBetween(
      _lastSearchPosition!.latitude,
      _lastSearchPosition!.longitude,
      _currentCameraPosition!.latitude,
      _currentCameraPosition!.longitude,
    );

    if (distance > 1000) {
      setState(() => _showSearchThisArea = true);
    }
  }

  void _updateMarkers() {
    final filteredReports =
        _selectedCategory == null || _selectedCategory == 'All'
            ? _reports
            : _reports
                .where((r) => r['category']
                    .toString()
                    .toLowerCase()
                    .contains(_selectedCategory!.toLowerCase()))
                .toList();

    final markers = filteredReports.map((report) {
      return Marker(
        markerId: MarkerId(report['id'].toString()),
        position: LatLng(
          (report['latitude'] as num?)?.toDouble() ?? 3.1390,
          (report['longitude'] as num?)?.toDouble() ?? 101.6869,
        ),
        infoWindow: InfoWindow(
          title: report['category'] ?? 'Scam Report',
          snippet: 'Tap for details',
          onTap: () => _showReportPeek(report),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getMarkerHue(report['category'] ?? ''),
        ),
      );
    }).toSet();

    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }

  double _getMarkerHue(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('phishing')) return BitmapDescriptor.hueOrange;
    if (cat.contains('investment')) return BitmapDescriptor.hueRed;
    if (cat.contains('e-wallet')) return BitmapDescriptor.hueAzure;
    if (cat.contains('courier')) return BitmapDescriptor.hueViolet;
    return BitmapDescriptor.hueRed;
  }

  void _showReportPeek(dynamic report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, controller) => Container(
          decoration: BoxDecoration(
            color: DesignTokens.colors.backgroundDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ScamCard(
                report: report,
                onVerify: () {
                  Navigator.pop(context);
                  _fetchReports(
                      lat: _lastSearchPosition?.latitude,
                      lng: _lastSearchPosition?.longitude,
                      radius: 5.0);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      useSafeArea: false,
      body: Stack(
        children: [
          // 1. MAP
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController?.setMapStyle(_mapStyle);
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            onLongPress: (latLng) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ScamReportEntryScreen(),
                ),
              ).then((_) => _fetchReports(
                  lat: _lastSearchPosition?.latitude,
                  lng: _lastSearchPosition?.longitude,
                  radius: 5.0));
            },
            markers: _markers,
            circles: _circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // 2. TOP BAR (Filters)
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildRoundButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassSurface(
                          borderRadius: 30,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.search,
                                  color: Colors.white70, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Search areas...',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Categories Horizontal List
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category ||
                          (_selectedCategory == null && category == 'All');

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = category);
                            _updateMarkers();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? DesignTokens.colors.accentGreen
                                  : DesignTokens.colors.backgroundDark.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? DesignTokens.colors.accentGreen
                                    : Colors.white24,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // SEARCH THIS AREA BUTTON
          if (_showSearchThisArea && !_isLoading)
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentCameraPosition != null) {
                      _fetchReports(
                        lat: _currentCameraPosition!.latitude,
                        lng: _currentCameraPosition!.longitude,
                        radius: 5.0,
                      );
                    }
                  },
                  child: GlassSurface(
                    borderRadius: 30,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.refresh, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'SEARCH THIS AREA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Long Press Tip
          if (!_isLoading)
            Positioned(
              bottom: 100,
              left: 20,
              child: GlassSurface(
                borderRadius: 12,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.touch_app_outlined,
                        color: DesignTokens.colors.accentGreen.withOpacity(0.7),
                        size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Long press to report a scam at a location',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),

          // 3. BOTTOM BUTTONS
          Positioned(
            bottom: 30,
            right: 20,
            child: Column(
              children: [
                _buildRoundButton(
                  icon: Icons.my_location,
                  onTap: _getUserLocation,
                ),
                const SizedBox(height: 12),
                _buildRoundButton(
                  icon: Icons.refresh,
                  onTap: () => _fetchReports(
                      lat: _lastSearchPosition?.latitude,
                      lng: _lastSearchPosition?.longitude,
                      radius: 5.0),
                ),
              ],
            ),
          ),

          if (_isLoading)
            Center(
              child: AppLoadingIndicator.center(),
            ),
        ],
      ),
    );
  }

  Widget _buildRoundButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassSurface(
        borderRadius: 50,
        padding: const EdgeInsets.all(12),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  // Dark Map Style
  final String _mapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#242f3e"
        }
      ]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#746855"
        }
      ]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "color": "#242f3e"
        }
      ]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#d59563"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#17263c"
        }
      ]
    }
  ]
  ''';
}
