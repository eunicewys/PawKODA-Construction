import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_url_extractor/google_maps_url_extractor.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pawkoda_fyp/models/clinic_model.dart';

class ClinicGoogleMapWidget extends StatefulWidget {
  final String clinicLink;
  final String? clinicName;
  final String? clinicAddress;

  const ClinicGoogleMapWidget({
    super.key,
    required this.clinicLink,
    this.clinicName,
    this.clinicAddress,
  });

  @override
  State<ClinicGoogleMapWidget> createState() => _ClinicGoogleMapWidgetState();
}

class _ClinicGoogleMapWidgetState extends State<ClinicGoogleMapWidget> {
  bool _isLoading = true;
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
    });

    try {
      double? lat;
      double? lng;

      // 1. Check strict pinpoint regex directly on widget.clinicLink
      final strict = ClinicModel.extractCoordinatesFromGoogleMapsUrlStrict(widget.clinicLink);
      if (strict != null) {
        lat = strict['latitude'];
        lng = strict['longitude'];
      } else {
        // 2. Try GoogleMapsUrlExtractor
        try {
          final dynamic rawResult = GoogleMapsUrlExtractor.extractCoordinates(widget.clinicLink);
          if (rawResult is Map) {
            lat = (rawResult['latitude'] ?? rawResult['lat'])?.toDouble();
            lng = (rawResult['longitude'] ?? rawResult['lng'])?.toDouble();
          } else if (rawResult != null) {
            try {
              lat = (rawResult.latitude as num?)?.toDouble();
              lng = (rawResult.longitude as num?)?.toDouble();
            } catch (_) {}
          }
        } catch (_) {}
      }

      // 3. Fall back to async Google Maps URL resolution (for short links like maps.app.goo.gl)
      if (lat == null || lng == null || lat == 0.0 || lng == 0.0) {
        final resolved = await ClinicModel.resolveGoogleMapsCoordinatesAsync(
          widget.clinicLink,
          widget.clinicAddress ?? '',
          widget.clinicName ?? '',
        );
        lat = resolved['latitude'];
        lng = resolved['longitude'];
      }

      if (lat != null && lng != null && lat != 0.0 && lng != 0.0 && mounted) {
        final LatLng targetLatLng = LatLng(lat, lng);

        setState(() {
          _extractedLatLng = targetLatLng;
          _isLoading = false;

          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('clinic_red_pin'),
              position: targetLatLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(
                title: widget.clinicName ?? "Clinic Location",
                snippet: "Lat: ${lat!.toStringAsFixed(5)}, Lng: ${lng!.toStringAsFixed(5)}",
              ),
            ),
          );
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(targetLatLng, 15.5),
        );
      } else if (mounted) {
        setState(() {
          _extractedLatLng = null;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _extractedLatLng = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchGoogleMapsUrl() async {
    final String urlStr = widget.clinicLink.trim();
    final Uri uri = Uri.parse(
      urlStr.isNotEmpty ? urlStr : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("${widget.clinicName ?? ''} ${widget.clinicAddress ?? 'Penang'}")}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
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
              const SizedBox(height: 12),
              Text(
                "Loading location...",
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

    // When coordinates are not directly extractable:
    // Show address words out clearly and button to redirect to Google Maps
    if (_extractedLatLng == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF556B2F).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF556B2F).withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFF556B2F), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.clinicName != null && widget.clinicName!.isNotEmpty)
                        Text(
                          widget.clinicName!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF263238),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        (widget.clinicAddress != null && widget.clinicAddress!.isNotEmpty)
                            ? widget.clinicAddress!
                            : "Penang, Malaysia",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _launchGoogleMapsUrl,
                icon: const Icon(Icons.directions_rounded, color: Colors.white, size: 18),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "Open in Google Maps",
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF556B2F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 320,
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
