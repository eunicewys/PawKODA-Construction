import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../models/pet_model.dart';
import '../../models/clinic_model.dart';
import '../../models/booking_model.dart';
import '../../services/pet_service.dart';
import '../../services/booking_service.dart';
import '../../services/notification_service.dart';
import '../widgets/fringe_header.dart';

/// BookingScreen: Dedicated vet clinic discovery and appointment booking module
/// focusing strictly on Penang, Malaysia with Google Maps integration.
class BookingScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  const BookingScreen({super.key, this.onBackPressed});

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

  final BookingService _bookingService = BookingService();
  final PetService _petService = PetService();

  late TabController _tabController;
  String _selectedCity = 'All Cities (Penang)';
  String _searchQuery = '';
  ClinicModel? _selectedMapClinic;
  bool _isMapView = false;
  bool _showAllClinics = false;
  final TextEditingController _searchCtrl = TextEditingController();

  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initUserLocation();
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
      body: SafeArea(
        child: Column(
          children: [
            // Header Fringe
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
      ),
    );
  }

  // ===========================================================================
  // TAB 1: DISCOVER CLINICS
  // ===========================================================================
  Widget _buildDiscoverClinicsTab(String userId) {
    final filteredClinics = _bookingService.getClinics(
      userLat: _userLat,
      userLng: _userLng,
      selectedCity: _selectedCity,
      searchQuery: _searchQuery,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LOCATION SELECTION CARD (Compact scale)
          _buildLocationCard(),
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
                if (filteredClinics.length > 3 && _searchQuery.isEmpty)
                  InkWell(
                    onTap: () => setState(() => _showAllClinics = !_showAllClinics),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _dustyOlive.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _showAllClinics ? "Show Top 3" : "See All (${filteredClinics.length})",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _dustyOlive,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            _showAllClinics ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 14,
                            color: _dustyOlive,
                          ),
                        ],
                      ),
                    ),
                  )
                else
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
              Builder(
                builder: (context) {
                  final displayList = (_showAllClinics || _searchQuery.isNotEmpty)
                      ? filteredClinics
                      : filteredClinics.take(3).toList();
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _buildClinicCard(displayList[index], userId);
                    },
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // LOCATION CARD (Scaled down compactness)
  // ===========================================================================
  Widget _buildLocationCard() {
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
                "LOCATION",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: _ashGrey,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _initUserLocation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _desertSand.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _userLat != null ? Icons.my_location : Icons.check_circle,
                        size: 11,
                        color: _dustyOlive,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _userLat != null ? "GPS Active (Precise Distance)" : "Penang, Malaysia",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _dustyOlive,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // City Selection Dropdown (Scaled down)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: _powderPetal.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _desertSand.withValues(alpha: 0.5)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCity,
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
                items: BookingService.penangCities.map<DropdownMenuItem<String>>((String city) {
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
                        Text(city, style: const TextStyle(fontSize: 13)),
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

                    // Rating, Distance & Hours
                    Row(
                      children: [
                        // Rating
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          "${clinic.rating}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _darkCharcoal,
                          ),
                        ),
                        Text(
                          " (${clinic.reviewCount})",
                          style: TextStyle(fontSize: 10, color: _ashGrey),
                        ),
                        const SizedBox(width: 8),

                        // Distance
                        Icon(Icons.near_me_rounded, color: _ashGrey, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          "${clinic.distanceKm} km",
                          style: TextStyle(fontSize: 10, color: _darkCharcoal),
                        ),
                        const SizedBox(width: 8),

                        // Hours
                        Icon(Icons.access_time_rounded, color: _ashGrey, size: 12),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            clinic.operatingHours,
                            style: TextStyle(
                              fontSize: 10,
                              color: clinic.isEmergency24h ? Colors.red.shade700 : _darkCharcoal,
                              fontWeight: clinic.isEmergency24h ? FontWeight.bold : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                onPressed: () => _showBookingModal(context, clinic, userId),
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

  // ===========================================================================
  // INTERACTIVE PENANG GOOGLE MAP VIEW
  // ===========================================================================
  Widget _buildPenangInteractiveMap(List<ClinicModel> clinics, String userId) {
    final activeClinic = _selectedMapClinic ?? (clinics.isNotEmpty ? clinics.first : null);

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _dustyOlive,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.map_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    "Penang Google Maps View",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${clinics.length} Pins",
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Visual Penang Map Representation
          Container(
            height: 200,
            width: double.infinity,
            color: const Color(0xFFE5E9EC),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PenangMapPainter(
                      selectedClinic: activeClinic,
                      allClinics: clinics,
                    ),
                  ),
                ),

                ...clinics.map((clinic) {
                  final isSelected = activeClinic?.id == clinic.id;
                  final normPos = _getNormPosForClinic(clinic);

                  return Positioned(
                    left: normPos.dx,
                    top: normPos.dy,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMapClinic = clinic),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.all(isSelected ? 6 : 4),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.red : _dustyOlive,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              clinic.isEmergency24h ? Icons.local_hospital : Icons.pets,
                              color: Colors.white,
                              size: isSelected ? 15 : 12,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? _darkCharcoal : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 3)],
                            ),
                            child: Text(
                              clinic.name.split(' ').first,
                              style: TextStyle(
                                color: isSelected ? Colors.white : _darkCharcoal,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.g_mobiledata, color: Colors.blue.shade700, size: 18),
                        const Text(
                          "Google Maps Penang",
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (activeClinic != null) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildClinicCard(activeClinic, userId),
            ),
          ],
        ],
      ),
    );
  }

  Offset _getNormPosForClinic(ClinicModel clinic) {
    double normX = ((clinic.longitude - 100.20) / (100.48 - 100.20)).clamp(0.1, 0.85);
    double normY = (1.0 - ((clinic.latitude - 5.15) / (5.52 - 5.15))).clamp(0.1, 0.82);
    return Offset(normX * 260 + 10, normY * 140 + 10);
  }

  Color _getClinicAvatarBg(String id) {
    switch (id) {
      case 'clinic_01':
        return const Color(0xFFE8F5E9);
      case 'clinic_02':
        return const Color(0xFFFFF3E0);
      case 'clinic_03':
        return const Color(0xFFF3E5F5);
      case 'clinic_04':
        return const Color(0xFFFFEBEE);
      case 'clinic_05':
        return const Color(0xFFE0F2F1);
      default:
        return _powderPetal;
    }
  }

  Future<void> _openGoogleMapsForClinic(ClinicModel clinic) async {
    final success = await _bookingService.openGoogleMaps(
      latitude: clinic.latitude,
      longitude: clinic.longitude,
      clinicName: clinic.name,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Opening Google Maps for ${clinic.name}..."),
          backgroundColor: _dustyOlive,
        ),
      );
    }
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

        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month, size: 52, color: _ashGrey),
                const SizedBox(height: 10),
                Text(
                  "No Appointments Yet",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _darkCharcoal),
                ),
                const SizedBox(height: 4),
                Text(
                  "Your booked appointments in Penang will appear here.",
                  style: TextStyle(color: _ashGrey, fontSize: 12),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(0),
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text("Find a Clinic", style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _dustyOlive,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: bookings.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _buildBookingItemCard(booking, userId);
          },
        );
      },
    );
  }

  Widget _buildBookingItemCard(BookingModel booking, String userId) {
    final bool isCancelled = booking.status == 'CANCELLED';
    final DateFormat formatter = DateFormat('EEE, dd MMM yyyy');

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? Colors.red.withValues(alpha: 0.12)
                      : Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  booking.status,
                  style: TextStyle(
                    color: isCancelled ? Colors.red : Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
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
              if (!isCancelled)
                TextButton(
                  onPressed: () => _confirmCancelBooking(context, booking.id, userId),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: const Text("Cancel Booking", style: TextStyle(color: Colors.red, fontSize: 11)),
                ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: () {
                  _bookingService.openGoogleMaps(
                    latitude: 5.4164,
                    longitude: 100.3327,
                    clinicName: booking.clinicName,
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

  // ===========================================================================
  // BOOKING MODAL SHEET (Scaled down compactness)
  // ===========================================================================
  void _showBookingModal(BuildContext context, ClinicModel clinic, String userId) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedTime = '10:30 AM';
    String selectedService = clinic.services.isNotEmpty ? clinic.services.first : 'General Checkup';
    PetProfile? selectedPet;
    final notesCtrl = TextEditingController();

    final timeSlots = [
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

                    _buildStepLabel("1. SELECT PET"),
                    StreamBuilder<List<PetProfile>>(
                      stream: _petService.streamUserPets(userId),
                      builder: (context, snapshot) {
                        final pets = snapshot.data ?? [];
                        if (pets.isEmpty) {
                          return const Text("No pets registered yet. Please add a pet first.", style: TextStyle(color: Colors.grey, fontSize: 12));
                        }
                        return SizedBox(
                          height: 48,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: pets.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 6),
                            itemBuilder: (context, idx) {
                              final p = pets[idx];
                              final isSel = selectedPet?.id == p.id;
                              return ChoiceChip(
                                label: Text("${p.name} (${p.species.name})"),
                                selected: isSel,
                                selectedColor: _dustyOlive,
                                visualDensity: VisualDensity.compact,
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : _darkCharcoal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                onSelected: (sel) {
                                  if (sel) setMState(() => selectedPet = p);
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildStepLabel("2. SERVICE TYPE"),
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

                    _buildStepLabel("3. APPOINTMENT DATE"),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setMState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _powderPetal.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _desertSand),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('EEEE, dd MMMM yyyy').format(selectedDate),
                              style: TextStyle(fontWeight: FontWeight.bold, color: _darkCharcoal, fontSize: 13),
                            ),
                            Icon(Icons.calendar_month, color: _dustyOlive, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildStepLabel("4. TIME SLOT"),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: timeSlots.map((slot) {
                        final isSel = selectedTime == slot;
                        return ChoiceChip(
                          label: Text(slot),
                          selected: isSel,
                          selectedColor: _dustyOlive,
                          visualDensity: VisualDensity.compact,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : _darkCharcoal,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          onSelected: (sel) {
                            if (sel) setMState(() => selectedTime = slot);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please select a pet first.")),
                            );
                            return;
                          }

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
                            bookingDate: selectedDate,
                            timeSlot: selectedTime,
                            notes: notesCtrl.text.trim(),
                            status: 'CONFIRMED',
                            createdAt: DateTime.now(),
                          );

                          await _bookingService.createBooking(booking);

                          await NotificationService().showNotification(
                            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                            title: "Vet Appointment Booked! 🐾",
                            body: "Confirmed with ${clinic.name} for ${selectedPet!.name} on ${DateFormat('dd MMM').format(selectedDate)} at $selectedTime.",
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
  }

  Widget _buildStepLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: _ashGrey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _PenangMapPainter extends CustomPainter {
  final ClinicModel? selectedClinic;
  final List<ClinicModel> allClinics;

  _PenangMapPainter({this.selectedClinic, required this.allClinics});

  @override
  void paint(Canvas canvas, Size size) {
    final landPaint = Paint()
      ..color = const Color(0xFFD4E0D7)
      ..style = PaintingStyle.fill;

    final seaPaint = Paint()
      ..color = const Color(0xFFCBE3EF)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), seaPaint);

    final islandPath = Path();
    islandPath.moveTo(size.width * 0.15, size.height * 0.2);
    islandPath.quadraticBezierTo(size.width * 0.35, size.height * 0.1, size.width * 0.45, size.height * 0.35);
    islandPath.quadraticBezierTo(size.width * 0.4, size.height * 0.75, size.width * 0.25, size.height * 0.85);
    islandPath.quadraticBezierTo(size.width * 0.1, size.height * 0.65, size.width * 0.15, size.height * 0.2);
    islandPath.close();
    canvas.drawPath(islandPath, landPaint);

    final mainlandPath = Path();
    mainlandPath.moveTo(size.width * 0.55, size.height * 0.05);
    mainlandPath.lineTo(size.width, size.height * 0.05);
    mainlandPath.lineTo(size.width, size.height * 0.95);
    mainlandPath.lineTo(size.width * 0.55, size.height * 0.95);
    mainlandPath.quadraticBezierTo(size.width * 0.52, size.height * 0.5, size.width * 0.55, size.height * 0.05);
    mainlandPath.close();
    canvas.drawPath(mainlandPath, landPaint);

    final bridgePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.38, size.height * 0.52),
      Offset(size.width * 0.56, size.height * 0.52),
      bridgePaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.32, size.height * 0.75),
      Offset(size.width * 0.58, size.height * 0.80),
      bridgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
