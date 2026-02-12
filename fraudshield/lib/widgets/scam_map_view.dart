import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/scam_card.dart';

class ScamMapView extends StatelessWidget {
  final List<dynamic> reports;
  final VoidCallback onRefresh;

  const ScamMapView({
    super.key,
    required this.reports,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Default center (Kuala Lumpur)
    const klCenter = LatLng(3.1390, 101.6869);

    final Set<Marker> markers = reports
        .where((r) => r['latitude'] != null && r['longitude'] != null)
        .map((report) {
      return Marker(
        markerId: MarkerId(report['id'].toString()),
        position: LatLng(
          (report['latitude'] as num).toDouble(),
          (report['longitude'] as num).toDouble(),
        ),
        infoWindow: InfoWindow(
          title: report['category'] ?? 'Scam',
          snippet: 'Tap to view details',
          onTap: () => _showReportDetails(context, report),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    }).toSet();

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: klCenter,
        zoom: 13.0,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapToolbarEnabled: true,
      zoomControlsEnabled: false,
    );
  }

  void _showReportDetails(BuildContext context, dynamic report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ScamCard(
                report: report,
                onVerify: () {
                  Navigator.pop(context);
                  onRefresh();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
