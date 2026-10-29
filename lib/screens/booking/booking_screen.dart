import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/user_provider.dart';
import '../../models/pet_model.dart';
import '../../models/clinic_model.dart';
import '../../models/booking_model.dart';
import '../../services/pet_service.dart';
import '../../services/booking_service.dart';
import '../../services/notification_service.dart';
import '../../services/user_notification_service.dart';
import '../widgets/fringe_header.dart';
import 'clinic_google_map_widget.dart';

/// CustomPainter that draws a diagonal slash line from top-right to bottom-left for closed operating days
class DiagonalSlashPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  DiagonalSlashPainter({
    required this.color,
    this.strokeWidth = 1.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(size.width - 8, 8), Offset(8, size.height - 8), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// BookingScreen: Dedicated vet clinic discovery and appointment booking module
/// focusing strictly on Penang, Malaysia with Google Maps integration.
class BookingScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  final int initialTabIndex;

  const BookingScreen({
    super.key,
    this.onBackPressed,
    this.initialTabIndex = 0,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with SingleTickerProviderStateMixin {
  // Official Morandi Natural Palette
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _lightBronze = const Color(0xFFCB997E);
  final Color _desertSand = const Color(0xFFDDBEA9);
  final Color _drySage = const Color(0xFFA5A58D);
  final Color _ashGrey = const Color(0xFFB7B7A4);
  final Color _darkCharcoal = const Color(0xFF2D3142);
  final Color _errorCoral = const Color(0xFFB56576);

  final BookingService _bookingService = BookingService();
  final PetService _petService = PetService();
  final MapController _mapController = MapController();

  late TabController _tabController;
  int _bookingSubTab = 0; // 0 = Active Bookings, 1 = Past Bookings
  String _selectedCity = 'All Cities (Penang)';
  String _searchQuery = '';
  ClinicModel? _selectedMapClinic;
  bool _isMapView = false;
  String _mapTileType = 'm'; // 'm' = Google Maps Standard, 's' = Satellite, 'y' = Hybrid
  final TextEditingController _searchCtrl = TextEditingController();

  double? _userLat;
  double? _userLng;

  bool _isBookingPast(BookingModel booking) {
    final statusUpper = booking.status.toUpperCase();
    if (statusUpper == 'COMPLETED' || statusUpper == 'CANCELLED') {
      return true;
    }

    DateTime apptDateTime = booking.bookingDate;
    try {
      if (booking.timeSlot.isNotEmpty) {
        final parts = booking.timeSlot.trim().split(' ');
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        final int minute = int.parse(timeParts[1]);
        final String period = parts[1].toUpperCase();

        if (period == 'PM' && hour < 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        apptDateTime = DateTime(
          booking.bookingDate.year,
          booking.bookingDate.month,
          booking.bookingDate.day,
          hour,
          minute,
        );
      }
    } catch (_) {}

    final cutoffTime = apptDateTime.add(const Duration(hours: 2));
    return DateTime.now().isAfter(cutoffTime);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _initUserLocation();
  }

  @override
  void didUpdateWidget(covariant BookingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      _tabController.animateTo(widget.initialTabIndex);
    }
  }

  Future<void> _initUserLocation() async {
    final pos = await _bookingService.getUserLocation();
    if (pos != null && mounted) {
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<UserProvider>().uid ?? '';

    return Scaffold(
      backgroundColor: _drySage,
      body: Column(
        children: [
          // Header Fringe (Sticks directly to top)
          FringeHeader(
            title: "Book a Vet",
            subtitle: "FIND CLINICS NEAR YOU IN PENANG, MALAYSIA",
            onBack: widget.onBackPressed,
          ),

            // Top Tab Toggle: Discover Clinics vs My Bookings (Kept as requested)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                dividerHeight: 0,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: _dustyOlive,
                  borderRadius: BorderRadius.circular(16),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: _darkCharcoal.withValues(alpha: 0.7),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(
                    height: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_rounded, size: 18),
                        SizedBox(width: 8),
                        Text("Find Clinics"),
                      ],
                    ),
                  ),
                  Tab(
                    height: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available_rounded, size: 18),
                        SizedBox(width: 8),
                        Text("My Bookings"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDiscoverClinicsTab(userId),
                  _buildMyBookingsTab(userId),
                ],
              ),
            ),
          ],
        ),
    );
  }

  // ===========================================================================
  // TAB 1: DISCOVER CLINICS
  // ===========================================================================
  Widget _buildDiscoverClinicsTab(String userId) {
    return StreamBuilder<List<ClinicModel>>(
      stream: _bookingService.streamLiveClinics(),
      builder: (context, snapshot) {
        final rawClinics = snapshot.data ?? [];
        final filteredClinics = _bookingService.processClinicsList(
          rawClinics,
          userLat: _userLat,
          userLng: _userLng,
          selectedCity: _selectedCity,
          searchQuery: _searchQuery,
        );

        final Set<String> dynamicCities = {'All Cities (Penang)'};
        for (var c in rawClinics) {
          if (c.city.isNotEmpty) dynamicCities.add(c.city);
        }
        final availableCities = dynamicCities.toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LOCATION SELECTION CARD (Compact scale)
              _buildLocationCardWithCities(availableCities),
              const SizedBox(height: 12),

          // Search Bar & View Mode Toggle (Slightly shrunk height & fonts)
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _drySage.withValues(alpha: 0.3)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: _darkCharcoal, fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      icon: Icon(Icons.search, color: _dustyOlive, size: 18),
                      hintText: "Search clinic or service...",
                      hintStyle: TextStyle(color: _ashGrey, fontSize: 12),
                      border: InputBorder.none,
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _isMapView = !_isMapView),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _isMapView ? _dustyOlive : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _dustyOlive),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isMapView ? Icons.list_rounded : Icons.map_rounded,
                        color: _isMapView ? Colors.white : _dustyOlive,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isMapView ? "List" : "Map",
                        style: TextStyle(
                          color: _isMapView ? Colors.white : _dustyOlive,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28), // Spacious gap between search bar and Recommended Clinics

          // VIEW CONTENT: Interactive Google Map or Recommended Clinics List
          if (_isMapView)
            _buildPenangInteractiveMap(filteredClinics, userId)
          else ...[
            // SECTION HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recommended Clinics",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _darkCharcoal,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _dustyOlive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${filteredClinics.length} Available",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _dustyOlive,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (filteredClinics.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredClinics.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _buildClinicCard(filteredClinics[index], userId);
                },
              ),
          ],
        ],
      ),
    );
      },
    );
  }

  // ===========================================================================
  // LOCATION CARD (Scaled down compactness)
  // ===========================================================================
  Widget _buildLocationCardWithCities(List<String> availableCities) {
    final String activeCityValue = availableCities.contains(_selectedCity)
        ? _selectedCity
        : availableCities.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: _lightBronze, size: 16),
              const SizedBox(width: 4),
              Text(
                "LOCATION (PENANG)",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: _ashGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // City Selection Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: _powderPetal.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _desertSand.withValues(alpha: 0.5)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: activeCityValue,
                isExpanded: true,
                isDense: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: _darkCharcoal, size: 20),
                style: TextStyle(
                  color: _darkCharcoal,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedCity = newValue);
                  }
                },
                items: availableCities.map<DropdownMenuItem<String>>((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Row(
                      children: [
                        Icon(
                          city == 'All Cities (Penang)' ? Icons.map : Icons.location_city_rounded,
                          size: 16,
                          color: _dustyOlive,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          city,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }



  // ===========================================================================
  // CLINIC CARD (Scaled down compact layout)
  // ===========================================================================
  Widget _buildClinicCard(ClinicModel clinic, String userId) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: clinic.isEmergency24h
            ? Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1.2)
            : null,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Icon (Slightly smaller size: 50x50)
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getClinicAvatarBg(clinic.id),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        clinic.isEmergency24h
                            ? Icons.local_hospital_rounded
                            : Icons.medical_services_rounded,
                        color: clinic.isEmergency24h ? Colors.red.shade700 : _dustyOlive,
                        size: 24,
                      ),
                    ),
                  ),
                  if (clinic.isEmergency24h)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "24H",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),

              // Clinic Details (Font scaled down)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      clinic.specialty,
                      style: TextStyle(
                        fontSize: 12,
                        color: _ashGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // City Location & Phone Number
                    Row(
                      children: [
                        Icon(Icons.location_city_rounded, color: _dustyOlive, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          clinic.city,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _darkCharcoal,
                          ),
                        ),
                        if (clinic.phone.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.phone_outlined, color: _dustyOlive, size: 13),
                          const SizedBox(width: 3),
                          Expanded(
                            child: SelectableText(
                              clinic.phone,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _darkCharcoal,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Full Operating Hours (Handles 1 or 2 time slots completely without cut-off)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.access_time_rounded, color: clinic.isEmergency24h ? Colors.red.shade700 : _dustyOlive, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "Operating Hours:\n${clinic.operatingHours.replaceAll(', ', '\n').replaceAll(' and ', '\n')}",
                            style: TextStyle(
                              fontSize: 11,
                              color: clinic.isEmergency24h ? Colors.red.shade700 : _darkCharcoal,
                              fontWeight: clinic.isEmergency24h ? FontWeight.bold : FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // City Badge & Action Buttons (Compact height)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _powderPetal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_city, size: 11, color: _dustyOlive),
                    const SizedBox(width: 3),
                    Text(
                      clinic.city,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _dustyOlive,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Google Maps Directions Button
              OutlinedButton.icon(
                onPressed: () => _openGoogleMapsForClinic(clinic),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _dustyOlive,
                  side: BorderSide(color: _dustyOlive.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.map, size: 14),
                label: const Text("Maps", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),

              // Book Now Button
              ElevatedButton(
                onPressed: () {
                  if (!clinic.isBookingReady) {
                    _showClinicUnavailableDialog(context, clinic);
                  } else {
                    _showBookingModal(context, clinic, userId);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _dustyOlive,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  visualDensity: VisualDensity.compact,
                  elevation: 0,
                ),
                child: const Text("Book", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  final Map<String, LatLng> _clinicCoordinatesCache = {};

  Future<Map<String, LatLng>> _resolveAllClinicCoordinates(List<ClinicModel> clinics) async {
    final Map<String, LatLng> results = {};

    for (final clinic in clinics) {
      if (_clinicCoordinatesCache.containsKey(clinic.id)) {
        results[clinic.id] = _clinicCoordinatesCache[clinic.id]!;
        continue;
      }

      LatLng? resolvedLatLng;

      // 1. Check if clinic already has valid custom non-default lat/lng
      if (clinic.latitude != 0.0 && clinic.longitude != 0.0 && (clinic.latitude != 5.4164 || clinic.longitude != 100.3327)) {
        resolvedLatLng = LatLng(clinic.latitude, clinic.longitude);
      }

      // 2. Resolve Google Maps URL or address asynchronously
      if (resolvedLatLng == null) {
        final String mapsUrl = (clinic.googleMapsUrl ?? '').trim();
        final Map<String, double> resolved = await ClinicModel.resolveGoogleMapsCoordinatesAsync(
          mapsUrl,
          clinic.address,
          clinic.name,
        );
        resolvedLatLng = LatLng(resolved['latitude']!, resolved['longitude']!);

        // Asynchronously update Firestore so future loads have the exact coordinates
        FirebaseFirestore.instance.collection('CLINICS').doc(clinic.id).set({
          'latitude': resolved['latitude'],
          'longitude': resolved['longitude'],
        }, SetOptions(merge: true));
      }

      _clinicCoordinatesCache[clinic.id] = resolvedLatLng;
      results[clinic.id] = resolvedLatLng;
    }

    return results;
  }

  // ===========================================================================
  // INTERACTIVE PENANG GOOGLE MAP VIEW (Rebuilt from scratch with exact plotting)
  // ===========================================================================
  Widget _buildPenangInteractiveMap(List<ClinicModel> clinics, String userId) {
    if (clinics.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Text("No clinics found for map plotting.", style: TextStyle(color: _ashGrey, fontSize: 13)),
      );
    }

    return FutureBuilder<Map<String, LatLng>>(
      future: _resolveAllClinicCoordinates(clinics),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Container(
            height: 330,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: _dustyOlive),
                  const SizedBox(height: 12),
                  Text("Plotting clinic locations on Google Maps...", style: TextStyle(color: _darkCharcoal, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }

        final Map<String, LatLng> coordsMap = snapshot.data ?? {};
        final selectedClinic = _selectedMapClinic;

        // Calculate initial map center and camera position
        LatLng initialCenter = const LatLng(5.3850, 100.3150); // Penang center
        if (selectedClinic != null && coordsMap.containsKey(selectedClinic.id)) {
          initialCenter = coordsMap[selectedClinic.id]!;
        } else if (coordsMap.isNotEmpty) {
          initialCenter = coordsMap.values.first;
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Google Maps Dark Header Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF263238),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text("G", style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.bold, fontSize: 15)),
                        Text("o", style: TextStyle(color: Color(0xFFEA4335), fontWeight: FontWeight.bold, fontSize: 15)),
                        Text("o", style: TextStyle(color: Color(0xFFFBBC05), fontWeight: FontWeight.bold, fontSize: 15)),
                        Text("g", style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.bold, fontSize: 15)),
                        Text("l", style: TextStyle(color: Color(0xFF34A853), fontWeight: FontWeight.bold, fontSize: 15)),
                        Text("e", style: TextStyle(color: Color(0xFFEA4335), fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Maps • Penang (${clinics.length} Plotted)",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              // Interactive Google Map
              Container(
                height: 330,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: initialCenter,
                        initialZoom: selectedClinic != null ? 15.0 : 11.5,
                        minZoom: 9.0,
                        maxZoom: 18.0,
                        onTap: (_, _) {
                          setState(() => _selectedMapClinic = null);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://mt1.google.com/vt/lyrs=$_mapTileType&x={x}&y={y}&z={z}',
                          userAgentPackageName: 'com.example.pawkoda_fyp',
                        ),
                        MarkerLayer(
                          markers: clinics.map((clinic) {
                            final LatLng pos = coordsMap[clinic.id] ?? LatLng(clinic.latitude, clinic.longitude);
                            final bool isSelected = selectedClinic?.id == clinic.id;

                            String pinLabel = clinic.name
                                .replaceAll('Veterinary Centre', 'Vet')
                                .replaceAll('Veterinary Clinic', 'Vet')
                                .replaceAll('Animal Hospital', 'Vet')
                                .replaceAll('Animal Clinic', 'Vet');

                            return Marker(
                              point: pos,
                              width: 90,
                              height: 60,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedMapClinic = clinic);
                                  _mapController.move(pos, 15.5);
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(
                                          Icons.location_on_sharp,
                                          color: isSelected ? const Color(0xFFD32F2F) : const Color(0xFFE53935),
                                          size: isSelected ? 38 : 28,
                                        ),
                                        Positioned(
                                          top: isSelected ? 8 : 5,
                                          child: Container(
                                            width: isSelected ? 10 : 8,
                                            height: isSelected ? 10 : 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSelected ? _darkCharcoal : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSelected ? Colors.red : Colors.grey.shade400,
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.18),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        pinLabel,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : _darkCharcoal,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    // Top Left: Map Tile Style Switcher (Roadmap / Satellite / Hybrid)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (_mapTileType == 'm') {
                              _mapTileType = 'y'; // Hybrid
                            } else if (_mapTileType == 'y') {
                              _mapTileType = 's'; // Satellite
                            } else {
                              _mapTileType = 'm'; // Roadmap
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _mapTileType == 'm' ? Icons.map_outlined : Icons.satellite_alt_rounded,
                                size: 14,
                                color: _dustyOlive,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _mapTileType == 'm' ? "Roadmap" : (_mapTileType == 'y' ? "Hybrid" : "Satellite"),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _darkCharcoal),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Zoom / Fit Controls
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              final currentZoom = _mapController.camera.zoom;
                              _mapController.move(_mapController.camera.center, currentZoom + 1.0);
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)],
                              ),
                              child: const Icon(Icons.add, size: 18, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () {
                              final currentZoom = _mapController.camera.zoom;
                              _mapController.move(_mapController.camera.center, currentZoom - 1.0);
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)],
                              ),
                              child: const Icon(Icons.remove, size: 18, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () {
                              if (selectedClinic != null && coordsMap.containsKey(selectedClinic.id)) {
                                _mapController.move(coordsMap[selectedClinic.id]!, 15.5);
                              } else {
                                _mapController.move(const LatLng(5.3850, 100.3150), 11.5);
                              }
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)],
                              ),
                              child: Icon(Icons.my_location, size: 16, color: _dustyOlive),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Selected Clinic Card Callout
              if (selectedClinic != null) ...[
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: _dustyOlive.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.pin_drop_rounded, size: 16, color: Colors.red.shade700),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Pin Selected: ${selectedClinic.name}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _darkCharcoal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() => _selectedMapClinic = null),
                              child: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildClinicCard(selectedClinic, userId),
                    ],
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app_rounded, size: 16, color: _dustyOlive),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Tap any pin marker to view clinic details and book appointment",
                          style: TextStyle(fontSize: 11, color: _ashGrey, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getClinicAvatarBg(String id) {
    final colors = const [
      Color(0xFFFFF3E0),
      Color(0xFFF3E5F5),
      Color(0xFFE8F5E9),
      Color(0xFFE0F2F1),
      Color(0xFFE3F2FD),
      Color(0xFFFFF8E1),
      Color(0xFFFCE4EC),
    ];
    return colors[id.hashCode.abs() % colors.length];
  }

  Future<void> _openGoogleMapsForClinic(ClinicModel clinic) async {
    final String mapsUrl = (clinic.googleMapsUrl ?? '').trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      clinic.name,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _darkCharcoal),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                clinic.address,
                style: TextStyle(fontSize: 12, color: _ashGrey),
              ),
              const SizedBox(height: 16),
              ClinicGoogleMapWidget(
                clinicLink: mapsUrl.isNotEmpty ? mapsUrl : 'https://maps.google.com/?q=${Uri.encodeComponent(clinic.name)}',
                clinicName: clinic.name,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _bookingService.openGoogleMaps(
                      clinicName: clinic.name,
                      address: clinic.address,
                      latitude: clinic.latitude,
                      longitude: clinic.longitude,
                      googleMapsUrl: clinic.googleMapsUrl,
                    );
                  },
                  icon: const Icon(Icons.directions, color: Colors.white),
                  label: const Text("Open in Google Maps App for Directions", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _dustyOlive,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 40, color: _ashGrey),
          const SizedBox(height: 8),
          Text(
            "No clinics found in $_selectedCity",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _darkCharcoal),
          ),
          const SizedBox(height: 4),
          Text(
            "Try changing city filter or searching for another term.",
            style: TextStyle(fontSize: 11, color: _ashGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: MY BOOKINGS
  // ===========================================================================
  Widget _buildMyBookingsTab(String userId) {
    if (userId.isEmpty) {
      return Center(
        child: Text("Please sign in to view your bookings.", style: TextStyle(color: _darkCharcoal, fontSize: 13)),
      );
    }

    return StreamBuilder<List<BookingModel>>(
      stream: _bookingService.streamUserBookings(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data ?? [];
        final activeList = bookings.where((b) => !_isBookingPast(b)).toList();
        final pastList = bookings.where((b) => _isBookingPast(b)).toList();

        final currentList = _bookingSubTab == 0 ? activeList : pastList;

        return Column(
          children: [
            // Sub-Tab Switcher
            Container(
              padding: const EdgeInsets.all(4),
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _drySage.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _bookingSubTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _bookingSubTab == 0 ? _dustyOlive : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Active Bookings (${activeList.length})",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _bookingSubTab == 0 ? Colors.white : _darkCharcoal,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _bookingSubTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _bookingSubTab == 1 ? _dustyOlive : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Past Bookings (${pastList.length})",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _bookingSubTab == 1 ? Colors.white : _darkCharcoal,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: currentList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _bookingSubTab == 0 ? Icons.calendar_today_rounded : Icons.history_rounded,
                            size: 48,
                            color: _ashGrey,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _bookingSubTab == 0 ? "No Active Appointments" : "No Past Appointments",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _darkCharcoal),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _bookingSubTab == 0
                                ? "Your upcoming Penang vet appointments will appear here."
                                : "Your past and completed vet appointment records will be stored here.",
                            style: TextStyle(color: _ashGrey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: currentList.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final booking = currentList[index];
                        return _buildBookingItemCard(booking, userId);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBookingItemCard(BookingModel booking, String userId) {
    final String statusUpper = booking.status.toUpperCase();
    final bool isPast = _isBookingPast(booking);
    final DateFormat formatter = DateFormat('EEE, dd MMM yyyy');

    Color badgeBgColor;
    Color badgeTextColor;
    String statusLabel;

    if (statusUpper == 'COMPLETED') {
      badgeBgColor = Colors.green.withValues(alpha: 0.15);
      badgeTextColor = Colors.green.shade800;
      statusLabel = "Completed";
    } else if (statusUpper == 'CANCELLED') {
      badgeBgColor = Colors.red.withValues(alpha: 0.12);
      badgeTextColor = Colors.red.shade800;
      statusLabel = "Cancelled";
    } else if (statusUpper == 'PENDING') {
      badgeBgColor = Colors.orange.withValues(alpha: 0.15);
      badgeTextColor = Colors.orange.shade900;
      statusLabel = "Pending";
    } else {
      // CONFIRMED
      if (isPast) {
        badgeBgColor = Colors.grey.withValues(alpha: 0.18);
        badgeTextColor = Colors.grey.shade800;
        statusLabel = "Expired";
      } else {
        badgeBgColor = Colors.green.withValues(alpha: 0.15);
        badgeTextColor = Colors.green.shade800;
        statusLabel = "Confirmed";
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.clinicName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _darkCharcoal,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: badgeTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (isPast || statusUpper == 'CANCELLED' || statusUpper == 'COMPLETED') ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _confirmDeleteBooking(context, booking.id, userId, booking.clinicName),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 15,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Divider(color: _drySage.withValues(alpha: 0.2)),
          const SizedBox(height: 6),

          Row(
            children: [
              Icon(Icons.pets, size: 13, color: _dustyOlive),
              const SizedBox(width: 4),
              Text(
                "Pet: ${booking.petName} (${booking.petSpecies})",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _darkCharcoal),
              ),
              const Spacer(),
              Icon(Icons.medical_services, size: 13, color: _lightBronze),
              const SizedBox(width: 4),
              Text(
                booking.serviceType,
                style: TextStyle(fontSize: 11, color: _ashGrey),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Row(
            children: [
              Icon(Icons.event, size: 13, color: _ashGrey),
              const SizedBox(width: 4),
              Text(
                formatter.format(booking.bookingDate),
                style: TextStyle(fontSize: 11, color: _darkCharcoal),
              ),
              const SizedBox(width: 12),
              Icon(Icons.access_time, size: 13, color: _ashGrey),
              const SizedBox(width: 4),
              Text(
                booking.timeSlot,
                style: TextStyle(fontSize: 11, color: _darkCharcoal, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 13, color: _dustyOlive),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "Vet: ${booking.preferredVet}",
                  style: TextStyle(fontSize: 11, color: _darkCharcoal, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (booking.notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              "Notes: ${booking.notes}",
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: _ashGrey),
            ),
          ],
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isPast && statusUpper != 'CANCELLED' && statusUpper != 'COMPLETED')
                TextButton(
                  onPressed: () => _confirmCancelBooking(context, booking.id, userId),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: const Text("Cancel Booking", style: TextStyle(color: Colors.red, fontSize: 11)),
                ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: () {
                  _bookingService.openGoogleMaps(
                    clinicName: booking.clinicName,
                    address: booking.clinicAddress,
                    latitude: 5.4056,
                    longitude: 100.3090,
                  );
                },
                icon: const Icon(Icons.directions, size: 13),
                label: const Text("Get Directions", style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _dustyOlive,
                  side: BorderSide(color: _dustyOlive.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmCancelBooking(BuildContext context, String bookingId, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Appointment?", style: TextStyle(fontSize: 16)),
        content: const Text("Are you sure you want to cancel this booking?", style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("No")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _bookingService.cancelBooking(userId, bookingId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Booking cancelled successfully.")),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBooking(BuildContext context, String bookingId, String userId, String clinicName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Remove Booking?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _darkCharcoal,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Are you sure you want to remove this cancelled booking record with $clinicName? This cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _darkCharcoal.withAlpha(200),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _ashGrey, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: _darkCharcoal,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _bookingService.deleteBooking(userId, bookingId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text("Booking record removed."),
                                backgroundColor: _dustyOlive,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          "Remove",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _errorCoral.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.priority_high_rounded,
                  color: _errorCoral,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _darkCharcoal,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _darkCharcoal.withAlpha(200),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _dustyOlive,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _parseTimeSlot(DateTime date, String slotStr) {
    try {
      final parts = slotStr.trim().split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      final String period = parts[1].toUpperCase();

      if (period == 'PM' && hour < 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return date;
    }
  }

  List<String> _getVetWorkingSlots(String vetName, List<String> defaultSlots) {
    final String trimmed = vetName.trim();
    if (trimmed.isEmpty || trimmed == 'Any Available Vet' || trimmed.startsWith('--')) {
      return defaultSlots; // No specific vet chosen: return all main available clinic slots
    }

    final String lower = trimmed.toLowerCase();

    // 1. Surgeon / Senior Vet Shift (e.g., Morning to Early Afternoon)
    if (lower.contains('surgeon') || lower.contains('senior') || lower.contains('lim') || lower.contains('kenique')) {
      return defaultSlots.where((s) => s.contains('08:00') || s.contains('09:00') || s.contains('10:30') || s.contains('02:00')).toList();
    }

    // 2. Feline / Specialist Shift (e.g., Mid-Day)
    if (lower.contains('feline') || lower.contains('specialist') || lower.contains('tan') || lower.contains('amanda')) {
      return defaultSlots.where((s) => s.contains('10:30') || s.contains('11:45') || s.contains('02:00') || s.contains('03:30')).toList();
    }

    // 3. General Practitioner / Evening Shift
    if (lower.contains('general') || lower.contains('practitioner') || lower.contains('wong') || lower.contains('marcus')) {
      return defaultSlots.where((s) => s.contains('02:00') || s.contains('03:30') || s.contains('05:00') || s.contains('07:30')).toList();
    }

    // Default deterministic shift distribution for any custom vet
    final int hash = trimmed.hashCode.abs() % 3;
    if (hash == 0) {
      return defaultSlots.where((s) => s.contains('08:00') || s.contains('09:00') || s.contains('10:30') || s.contains('02:00')).toList();
    } else if (hash == 1) {
      return defaultSlots.where((s) => s.contains('10:30') || s.contains('11:45') || s.contains('02:00') || s.contains('03:30')).toList();
    } else {
      return defaultSlots.where((s) => s.contains('02:00') || s.contains('03:30') || s.contains('05:00') || s.contains('07:30')).toList();
    }
  }

  List<String> _getAvailableTimeSlots(DateTime date, List<String> allSlots, {String selectedVet = ''}) {
    // Filter time slots based on doctor personnel schedule/availability
    final vetWorkingSlots = _getVetWorkingSlots(selectedVet, allSlots);

    final now = DateTime.now();
    final bool isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    if (!isToday) {
      return vetWorkingSlots;
    }

    // If current time is after 5:00 PM (17:00), same-day bookings are closed
    if (now.hour >= 17) {
      return [];
    }

    // Slots must be at least 3 hours later than current time
    final minAllowedTime = now.add(const Duration(hours: 3));

    return vetWorkingSlots.where((slot) {
      final slotDateTime = _parseTimeSlot(date, slot);
      return !slotDateTime.isBefore(minAllowedTime);
    }).toList();
  }

  /// Check if a specific time slot on a specific date is booked (PENDING or CONFIRMED)
  bool _isSlotBooked({
    required DateTime date,
    required String slot,
    required String selectedVet,
    required List<BookingModel> activeBookings,
  }) {
    final String targetSlot = slot.trim().toLowerCase();
    final String sVet = selectedVet.trim();
    final bool sIsAny = sVet.isEmpty || sVet == 'Any Available Vet' || sVet.startsWith('--');

    return activeBookings.any((b) {
      final bool sameDate = b.bookingDate.year == date.year &&
          b.bookingDate.month == date.month &&
          b.bookingDate.day == date.day;
      if (!sameDate) return false;

      final bool sameSlot = b.timeSlot.trim().toLowerCase() == targetSlot;
      if (!sameSlot) return false;

      final String bVet = b.preferredVet.trim();
      final bool bIsAny = bVet.isEmpty || bVet == 'Any Available Vet' || bVet.startsWith('--');

      // If either user requested "Any Available Vet", or both requested the same vet, lock slot
      if (sIsAny || bIsAny) {
        return true;
      }

      return bVet.toLowerCase() == sVet.toLowerCase();
    });
  }

  /// Check if all available time slots on a specific date are booked
  bool _isDateFullyBooked({
    required DateTime date,
    required List<String> allSlots,
    required String selectedVet,
    required List<BookingModel> activeBookings,
  }) {
    final slotsForDay = _getAvailableTimeSlots(date, allSlots, selectedVet: selectedVet);
    if (slotsForDay.isEmpty) {
      return true; // No time slots available at all for this day
    }

    return slotsForDay.every((slot) => _isSlotBooked(
      date: date,
      slot: slot,
      selectedVet: selectedVet,
      activeBookings: activeBookings,
    ));
  }

  void _showClinicUnavailableDialog(BuildContext context, ClinicModel clinic) {
    final String phone = clinic.phone.trim();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.store_mall_directory_outlined,
                  color: Colors.amber.shade800,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Service Unavailable",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _darkCharcoal,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Service for ${clinic.name} is currently unavailable. Please contact clinic phone number.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ashGrey,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              if (phone.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone, size: 16, color: _dustyOlive),
                      const SizedBox(width: 8),
                      Text(
                        phone,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _darkCharcoal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ashGrey,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dustyOlive,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final Uri telUri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
                          if (await canLaunchUrl(telUri)) {
                            await launchUrl(telUri);
                          }
                        },
                        icon: const Icon(Icons.call, size: 16),
                        label: const Text("CALL VET", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BOOKING MODAL SHEET (Scaled down compactness)
  // ===========================================================================
  void _showBookingModal(BuildContext context, ClinicModel clinic, String userId) {
    if (!clinic.isBookingReady) {
      _showClinicUnavailableDialog(context, clinic);
      return;
    }

    DateTime? selectedDate;
    String selectedTime = '';
    String selectedService = clinic.services.isNotEmpty ? clinic.services.first : 'General Checkup';
    String selectedVet = '-- Select if any --';
    PetProfile? selectedPet;
    final notesCtrl = TextEditingController();

    final timeSlots = [
      '08:00 AM',
      '09:00 AM',
      '10:30 AM',
      '11:45 AM',
      '02:00 PM',
      '03:30 PM',
      '05:00 PM',
      '07:30 PM',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setMState) {
            return StreamBuilder<List<BookingModel>>(
              stream: _bookingService.streamClinicActiveBookings(clinic.id),
              builder: (context, bookingSnapshot) {
                final activeClinicBookings = bookingSnapshot.data ?? [];

                return Container(
                  height: MediaQuery.of(context).size.height * 0.82,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _ashGrey.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: _powderPetal,
                              child: Icon(Icons.local_hospital, color: _dustyOlive, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Book Appointment",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _darkCharcoal),
                                  ),
                                  Text(
                                    "${clinic.name} • ${clinic.city}",
                                    style: TextStyle(fontSize: 11, color: _ashGrey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Divider(color: _drySage.withValues(alpha: 0.2)),

                        _buildStepLabel("1. SELECT PET", isRequired: true),
                        StreamBuilder<List<PetProfile>>(
                          stream: _petService.streamUserPets(userId),
                          builder: (context, snapshot) {
                            final pets = snapshot.data ?? [];
                            if (pets.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "No pets registered yet. Please add a pet first.",
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic),
                                ),
                              );
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _ashGrey.withAlpha(100)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButtonFormField<String>(
                                  initialValue: selectedPet?.id,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    hintText: "-- Select a pet --",
                                    hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal, fontSize: 13),
                                    fillColor: Colors.transparent,
                                    filled: true,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                    border: InputBorder.none,
                                  ),
                                  dropdownColor: Colors.white,
                                  style: TextStyle(fontWeight: FontWeight.w600, color: _darkCharcoal, fontSize: 13),
                                  items: pets.map((p) => DropdownMenuItem<String>(
                                    value: p.id,
                                    child: Text(
                                      "${p.name} (${p.breed})",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontWeight: FontWeight.bold, color: _darkCharcoal, fontSize: 13),
                                    ),
                                  )).toList(),
                                  onChanged: (petId) {
                                    if (petId != null) {
                                      setMState(() {
                                        selectedPet = pets.firstWhere((p) => p.id == petId);
                                      });
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        _buildStepLabel("2. SERVICE TYPE", isRequired: true),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: clinic.services.map((svc) {
                            final isSel = selectedService == svc;
                            return ChoiceChip(
                              label: Text(svc),
                              selected: isSel,
                              selectedColor: _lightBronze,
                              visualDensity: VisualDensity.compact,
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : _darkCharcoal,
                                fontSize: 11,
                              ),
                              onSelected: (sel) {
                                if (sel) setMState(() => selectedService = svc);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),

                        _buildStepLabel("3. PREFERRED VET / SURGEON (OPTIONAL)"),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _ashGrey.withAlpha(100)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedVet,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                fillColor: Colors.transparent,
                                filled: true,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                                border: InputBorder.none,
                              ),
                              dropdownColor: Colors.white,
                              style: TextStyle(fontWeight: FontWeight.w600, color: _darkCharcoal, fontSize: 13),
                              items: [
                                "-- Select if any --",
                                ...clinic.veterinarians,
                              ].map((v) => DropdownMenuItem<String>(
                                value: v,
                                child: Text(
                                  v,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: v.startsWith("--") ? FontWeight.normal : FontWeight.bold,
                                    color: v.startsWith("--") ? Colors.grey.shade600 : _darkCharcoal,
                                    fontStyle: v.startsWith("--") ? FontStyle.italic : FontStyle.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              )).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setMState(() {
                                    selectedVet = val;
                                    // Re-check time slot validity when vet personnel changes
                                    if (selectedDate != null) {
                                      final vetSlots = _getAvailableTimeSlots(selectedDate!, timeSlots, selectedVet: selectedVet);
                                      if (selectedTime.isNotEmpty && !vetSlots.contains(selectedTime)) {
                                        selectedTime = '';
                                      }
                                      if (_isDateFullyBooked(
                                        date: selectedDate!,
                                        allSlots: timeSlots,
                                        selectedVet: selectedVet,
                                        activeBookings: activeClinicBookings,
                                      )) {
                                        selectedDate = null;
                                        selectedTime = '';
                                      }
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildStepLabel("4. APPOINTMENT DATE AND TIME", isRequired: true),
                        Builder(
                          builder: (context) {
                            final nowTime = DateTime.now();
                            final bool isAfter5PM = nowTime.hour >= 17;
                            final DateTime startDate = isAfter5PM 
                                ? DateTime(nowTime.year, nowTime.month, nowTime.day + 1) 
                                : DateTime(nowTime.year, nowTime.month, nowTime.day);

                            final List<DateTime> weekDays = List.generate(
                              7, 
                              (i) => DateTime(startDate.year, startDate.month, startDate.day + i),
                            );

                            return SizedBox(
                              height: 72,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: weekDays.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 8),
                                itemBuilder: (context, idx) {
                                  final date = weekDays[idx];
                                  final bool isSelected = selectedDate != null &&
                                      date.year == selectedDate!.year &&
                                      date.month == selectedDate!.month &&
                                      date.day == selectedDate!.day;

                                  final bool isOpenDay = clinic.isOperatingDay(date);

                                  final bool isFullyBooked = isOpenDay && _isDateFullyBooked(
                                    date: date,
                                    allSlots: timeSlots,
                                    selectedVet: selectedVet,
                                    activeBookings: activeClinicBookings,
                                  );

                                  final String dayName = DateFormat('EEE').format(date);
                                  final String monthDay = DateFormat('dd MMM').format(date);

                                  final Widget cardChild = Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        dayName.toUpperCase(),
                                        style: TextStyle(
                                          color: (!isOpenDay || isFullyBooked)
                                              ? Colors.grey.shade400
                                              : (isSelected ? Colors.white70 : _ashGrey),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        monthDay,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: (!isOpenDay || isFullyBooked)
                                              ? Colors.grey.shade400
                                              : (isSelected ? Colors.white : _darkCharcoal),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (!isOpenDay) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          "CLOSED",
                                          style: TextStyle(
                                            color: Colors.red.shade400,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ] else if (isFullyBooked) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          "FULL",
                                          style: TextStyle(
                                            color: Colors.red.shade400,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ],
                                  );

                                  return GestureDetector(
                                    onTap: () {
                                      if (!isOpenDay) {
                                        _showBookingErrorDialog(
                                          modalCtx,
                                          "Clinic Closed",
                                          "Sorry, ${clinic.name} is closed on ${DateFormat('EEEE').format(date)}s. Please select an operating day.",
                                        );
                                        return;
                                      }
                                      if (isFullyBooked) {
                                        _showBookingErrorDialog(
                                          modalCtx,
                                          "Fully Booked",
                                          "Sorry, Fully Booked. Please consider other day(s)",
                                        );
                                        return;
                                      }
                                      setMState(() {
                                        selectedDate = date;
                                        selectedTime = ''; // Reset time slot when date changes
                                      });
                                    },
                                    child: CustomPaint(
                                      foregroundPainter: !isOpenDay
                                          ? DiagonalSlashPainter(color: Colors.red.shade300, strokeWidth: 1.8)
                                          : null,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 68,
                                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                        decoration: BoxDecoration(
                                          color: (!isOpenDay || isFullyBooked)
                                              ? Colors.grey.shade100
                                              : (isSelected ? _dustyOlive : Colors.white),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: (!isOpenDay || isFullyBooked)
                                                ? Colors.grey.shade300
                                                : (isSelected ? _dustyOlive : _ashGrey.withAlpha(100)),
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isSelected ? _dustyOlive.withAlpha(50) : Colors.black.withAlpha(8),
                                              blurRadius: isSelected ? 6 : 3,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: cardChild,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),

                        if (selectedDate == null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              "Please select an available date above to view time slots.",
                              style: TextStyle(color: _ashGrey, fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ] else ...[
                          Builder(
                            builder: (context) {
                              final slotsForDay = _getAvailableTimeSlots(selectedDate!, timeSlots, selectedVet: selectedVet);

                              if (selectedTime.isNotEmpty &&
                                  (_isSlotBooked(
                                        date: selectedDate!,
                                        slot: selectedTime,
                                        selectedVet: selectedVet,
                                        activeBookings: activeClinicBookings,
                                      ) ||
                                      !slotsForDay.contains(selectedTime))) {
                                selectedTime = '';
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Available time slots for ${DateFormat('EEE, dd MMM').format(selectedDate!)}:",
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _darkCharcoal),
                                  ),
                                  const SizedBox(height: 6),
                                  if (slotsForDay.isEmpty) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.amber.shade300),
                                      ),
                                      child: Text(
                                        DateTime.now().hour >= 17 && selectedDate!.day == DateTime.now().day
                                            ? "Same-day bookings are closed after 5:00 PM. Please select a date from tomorrow onwards."
                                            : "Sorry, Fully Booked. Please consider other day(s)",
                                        style: TextStyle(color: Colors.amber.shade900, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ] else ...[
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: slotsForDay.map((slot) {
                                        final bool isLocked = _isSlotBooked(
                                          date: selectedDate!,
                                          slot: slot,
                                          selectedVet: selectedVet,
                                          activeBookings: activeClinicBookings,
                                        );
                                        final isSel = selectedTime == slot;

                                        return ChoiceChip(
                                          avatar: isLocked
                                              ? Icon(Icons.lock_clock_rounded, size: 14, color: Colors.grey.shade400)
                                              : null,
                                          label: Text(
                                            slot,
                                            style: TextStyle(
                                              color: isLocked
                                                  ? Colors.grey.shade400
                                                  : (isSel ? Colors.white : _darkCharcoal),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              decoration: isLocked ? TextDecoration.lineThrough : TextDecoration.none,
                                            ),
                                          ),
                                          selected: isSel && !isLocked,
                                          selectedColor: _dustyOlive,
                                          disabledColor: Colors.grey.shade100,
                                          visualDensity: VisualDensity.compact,
                                          onSelected: isLocked
                                              ? (_) {
                                                  _showBookingErrorDialog(
                                                    modalCtx,
                                                    "Slot Locked",
                                                    "This time slot has already been booked. Please choose another time slot.",
                                                  );
                                                }
                                              : (sel) {
                                                  if (sel) setMState(() => selectedTime = slot);
                                                },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                ],
                              );
                            },
                          ),
                        ],

                        _buildStepLabel("5. NOTES & SYMPTOMS (OPTIONAL)"),
                        TextField(
                          controller: notesCtrl,
                          maxLines: 2,
                          style: TextStyle(fontSize: 12, color: _darkCharcoal),
                          decoration: InputDecoration(
                            hintText: "E.g., Routine health check, vaccination update...",
                            hintStyle: TextStyle(color: _ashGrey, fontSize: 12),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _dustyOlive,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () async {
                              if (selectedPet == null) {
                                _showBookingErrorDialog(
                                  context,
                                  "Pet Selection Required",
                                  "Please select a pet before confirming your appointment.",
                                );
                                return;
                              }

                              if (selectedService.isEmpty) {
                                _showBookingErrorDialog(
                                  context,
                                  "Service Required",
                                  "Please select a service type for your appointment.",
                                );
                                return;
                              }

                              if (selectedDate == null) {
                                _showBookingErrorDialog(
                                  context,
                                  "Date Required",
                                  "Please select an appointment date from the schedule grid.",
                                );
                                return;
                              }

                              if (selectedTime.isEmpty) {
                                _showBookingErrorDialog(
                                  context,
                                  "Time Slot Required",
                                  "Please select an available time slot for your appointment.",
                                );
                                return;
                              }

                              // Pre-check if slot is locked right before confirmation
                              final bool doubleCheckLocked = _isSlotBooked(
                                date: selectedDate!,
                                slot: selectedTime,
                                selectedVet: selectedVet,
                                activeBookings: activeClinicBookings,
                              );

                              if (doubleCheckLocked) {
                                _showBookingErrorDialog(
                                  context,
                                  "Time Slot Locked",
                                  "Sorry, this time slot was just booked by another user. Please select another time slot or day.",
                                );
                                setMState(() => selectedTime = '');
                                return;
                              }

                              final userProvider = Provider.of<UserProvider>(context, listen: false);
                              final String userName = userProvider.displayName?.isNotEmpty == true ? userProvider.displayName! : "Pet Owner";

                              final booking = BookingModel(
                                id: '',
                                userId: userId,
                                petId: selectedPet!.id,
                                petName: selectedPet!.name,
                                petSpecies: selectedPet!.species.name,
                                clinicId: clinic.id,
                                clinicName: clinic.name,
                                clinicAddress: clinic.address,
                                clinicPhone: clinic.phone,
                                city: clinic.city,
                                serviceType: selectedService,
                                bookingDate: selectedDate!,
                                timeSlot: selectedTime,
                                preferredVet: (selectedVet.startsWith("--") || selectedVet.isEmpty) ? "Any Available Vet" : selectedVet,
                                notes: notesCtrl.text.trim(),
                                status: 'PENDING',
                                createdAt: DateTime.now(),
                              );

                              try {
                                await _bookingService.createBookingWithAtomicLock(booking);

                                await NotificationService().showNotification(
                                  id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                                  title: "Booking Submitted (Pending)",
                                  body: "Your booking request with ${clinic.name} for ${selectedPet!.name} on ${DateFormat('dd MMM').format(selectedDate!)} at $selectedTime is pending vet confirmation.",
                                );

                                // 1. Log notification for Pet Owner
                                await UserNotificationService().logNotification(
                                  userId: userId,
                                  title: "Booking Submitted (Pending)",
                                  body: "Your booking request with ${clinic.name} for ${selectedPet!.name} on ${DateFormat('dd MMM').format(selectedDate!)} at $selectedTime is pending vet confirmation.",
                                  type: 'booking',
                                );

                                // 2. Log notification for Vet / Clinic
                                await UserNotificationService().logNotification(
                                  userId: clinic.id,
                                  title: "New Appointment Request 🐾",
                                  body: "New booking request from $userName for ${selectedPet!.name} (${selectedPet!.species.name}) on ${DateFormat('dd MMM').format(selectedDate!)} at $selectedTime.",
                                  type: 'booking',
                                );

                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  _tabController.animateTo(1);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Appointment booked with ${clinic.name}!"),
                                      backgroundColor: _dustyOlive,
                                    ),
                                  );
                                }
                              } catch (e) {
                                final String errorMsg = e is FirebaseException && e.message != null
                                    ? e.message!
                                    : "Sorry! This time slot was just booked by another user. Please select another time slot or day.";

                                if (context.mounted) {
                                  _showBookingErrorDialog(
                                    modalCtx,
                                    "Booking Conflict",
                                    errorMsg,
                                  );
                                  setMState(() => selectedTime = '');
                                }
                              }
                            },
                            child: const Text(
                              "CONFIRM APPOINTMENT",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStepLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: _ashGrey,
            letterSpacing: 0.8,
          ),
          children: isRequired
              ? [
                  const TextSpan(
                    text: " *",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ]
              : [],
        ),
      ),
    );
  }
}
