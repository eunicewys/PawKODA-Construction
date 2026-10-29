import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_url_extractor/google_maps_url_extractor.dart';

class ClinicGoogleMapWidget extends StatefulWidget {
  final String clinicLink;
  final String? clinicName;

  const ClinicGoogleMapWidget({
    super.key,
    required this.clinicLink,
    this.clinicName,
  });

  @override
  State<ClinicGoogleMapWidget> createState() => _ClinicGoogleMapWidgetState();
}

class _ClinicGoogleMapWidgetState extends State<ClinicGoogleMapWidget> {
  bool _isLoading = true;
  String? _errorMessage;
  LatLng? _extractedLatLng;
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _extractAndLoadMap();
  }

  @override
  void didUpdateWidget(covariant ClinicGoogleMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clinicLink != widget.clinicLink) {
      _extractAndLoadMap();
    }
  }

  Future<void> _extractAndLoadMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Asynchronously expand short Google Maps link & extract coordinates
      final dynamic rawResult = GoogleMapsUrlExtractor.extractCoordinates(widget.clinicLink);

      double? lat;
      double? lng;

      if (rawResult is Map) {
        lat = (rawResult['latitude'] ?? rawResult['lat'])?.toDouble();
        lng = (rawResult['longitude'] ?? rawResult['lng'])?.toDouble();
      } else if (rawResult != null) {
        try {
          lat = (rawResult.latitude as num?)?.toDouble();
          lng = (rawResult.longitude as num?)?.toDouble();
        } catch (_) {}
      }

      if (lat != null && lng != null && mounted) {
        final LatLng targetLatLng = LatLng(lat, lng);

        setState(() {
          _extractedLatLng = targetLatLng;
          _isLoading = false;

          // 4. Plot a single RED Marker (pin) directly on those coordinates using _markers
          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('clinic_red_pin'),
              position: targetLatLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(
                title: widget.clinicName ?? "Clinic Location",
                snippet: "Lat: ${lat?.toStringAsFixed(5)}, Lng: ${lng?.toStringAsFixed(5)}",
              ),
            ),
          );
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(targetLatLng, 15.5),
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Unable to extract valid coordinates from the provided Google Maps link.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to expand Google Maps link: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 2. Display CircularProgressIndicator while link is expanding
    if (_isLoading) {
      return Container(
        height: 320,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF556B2F)),
              ),
              const SizedBox(height: 16),
              Text(
                "Expanding Google Maps link & resolving location...",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _extractedLatLng == null) {
      return Container(
        height: 200,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 36),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? "Coordinates not found.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _extractAndLoadMap,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text("Retry Expansion"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Load GoogleMap widget centered on extracted coordinates with RED marker
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 350,
        width: double.infinity,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _extractedLatLng!,
            zoom: 15.5,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: true,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
        ),
      ),
    );
  }
}
