import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/clinic_model.dart';
import '../models/booking_model.dart';

/// BookingService: Handles Penang vet clinic listings featuring Kenique Veterinary Centre
/// and the 6 requested Penang clinics with exact Google Maps review counts & locations.
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Penang Cities List (strictly focused on Penang, Malaysia)
  static const List<String> penangCities = [
    'All Cities (Penang)',
    'George Town',
    'Bayan Lepas',
    'Tanjung Tokong',
    'Air Itam',
    'Balik Pulau',
    'Bukit Mertajam',
  ];

  /// Penang Central Benchmark Location (George Town / Bayan Lepas center: 5.4164, 100.3327)
  static const double defaultUserLat = 5.4164;
  static const double defaultUserLng = 100.3327;

  /// Formats any phone number into Malaysian standard e.g. "+60 4-281 1228" or "+60 12-345 6789"
  static String formatPhoneWithHyphen(String raw) {
    if (raw.trim().isEmpty) return '';

    String cleaned = raw.trim();
    String digits = cleaned.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.startsWith('60')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.isEmpty) return raw;

    // Landline Area Codes (4, 3, 5, 6, 7, 8, 9)
    if (digits.startsWith('4') || digits.startsWith('3') || digits.startsWith('5') || digits.startsWith('6') || digits.startsWith('7') || digits.startsWith('8') || digits.startsWith('9')) {
      final area = digits.substring(0, 1);
      final rest = digits.substring(1);
      if (rest.length >= 7) {
        return '+60 $area-${rest.substring(0, 3)} ${rest.substring(3)}';
      } else if (rest.length >= 4) {
        return '+60 $area-${rest.substring(0, 3)} ${rest.substring(3)}';
      }
      return '+60 $area-$rest';
    }

    // Mobile Area Codes (10, 11, 12, 13, 14, 15, 16, 17, 18, 19)
    if (digits.length >= 7) {
      final area = digits.substring(0, 2);
      final rest = digits.substring(2);
      if (rest.length >= 7) {
        return '+60 $area-${rest.substring(0, 4)} ${rest.substring(4)}';
      } else if (rest.length >= 6) {
        return '+60 $area-${rest.substring(0, 3)} ${rest.substring(3)}';
      } else if (rest.length >= 3) {
        return '+60 $area-${rest.substring(0, 3)} ${rest.substring(3)}';
      }
    }

    return '+60 $digits';
  }

  /// Parses exact latitude & longitude coordinates from any Google Maps link, landmark, or address
  static Map<String, double> parseExactCoordinatesFromGoogleMapsUrl(String mapsUrl, String address, String clinicName) {
    return ClinicModel.parseExactCoordinatesFromGoogleMapsUrl(mapsUrl, address, clinicName);
  }

  /// Calculate precise geodesic distance between user's coordinates and vet clinic
  static double calculateDistanceKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    const double earthRadiusKm = 6371.0;

    double dLat = _degreesToRadians(endLat - startLat);
    double dLng = _degreesToRadians(endLng - startLng);

    double lat1 = _degreesToRadians(startLat);
    double lat2 = _degreesToRadians(endLat);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLng / 2) * math.sin(dLng / 2) * math.cos(lat1) * math.cos(lat2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  /// Get current user live GPS position
  Future<Position?> getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint("Location service error: $e");
      return null;
    }
  }

  static const Set<String> legacySampleIds = {
    'kenique_01',
    'neko_inu_01',
    'joyful_pet_vet',
    'angsana_vet',
    'ark_vet_01',
    'jpv_penang',
    'ppv_barat_daya',
  };

  /// One-time cleanup function to delete pre-existing legacy mock clinics from Firestore
  static Future<void> purgeLegacySampleClinicsFromFirestore() async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    for (String legacyId in legacySampleIds) {
      try {
        await db.collection('CLINICS').doc(legacyId).delete();
        await db.collection('USERS').doc(legacyId).delete();
      } catch (e) {
        debugPrint("Error purging legacy clinic $legacyId: $e");
      }
    }
  }

  /// Stream live clinics strictly from Firestore `CLINICS` collection (100% registered clinics)
  Stream<List<ClinicModel>> streamLiveClinics() {
    purgeLegacySampleClinicsFromFirestore();
    return _db.collection('CLINICS').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => !legacySampleIds.contains(doc.id) && !legacySampleIds.contains(doc.id.toLowerCase()))
          .map((doc) {
        final data = doc.data();
        return ClinicModel.fromMap(data, doc.id);
      }).toList();
    });
  }

  /// Process clinics list with GPS distances and filters
  List<ClinicModel> processClinicsList(
    List<ClinicModel> rawClinics, {
    double? userLat,
    double? userLng,
    String selectedCity = 'All Cities (Penang)',
    String searchQuery = '',
  }) {
    final double actualUserLat = userLat ?? defaultUserLat;
    final double actualUserLng = userLng ?? defaultUserLng;

    List<ClinicModel> calculated = rawClinics.map((clinic) {
      double dist = calculateDistanceKm(
        startLat: actualUserLat,
        startLng: actualUserLng,
        endLat: clinic.latitude,
        endLng: clinic.longitude,
      );
      return clinic.copyWithDistance(dist);
    }).toList();

    calculated.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return calculated.where((clinic) {
      final matchesCity = (selectedCity == 'All Cities (Penang)' || selectedCity == 'All' || selectedCity == 'All Cities') ||
          clinic.city.toLowerCase().contains(selectedCity.toLowerCase()) ||
          selectedCity.toLowerCase().contains(clinic.city.toLowerCase());
      final matchesQuery = searchQuery.isEmpty ||
          clinic.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          clinic.specialty.toLowerCase().contains(searchQuery.toLowerCase()) ||
          clinic.city.toLowerCase().contains(searchQuery.toLowerCase()) ||
          clinic.services.any((s) => s.toLowerCase().contains(searchQuery.toLowerCase()));
      return matchesCity && matchesQuery;
    }).toList();
  }

  /// Get clinics with precise distance calculated from user's place & sorted by nearest distance
  Future<List<ClinicModel>> getClinics({
    double? userLat,
    double? userLng,
    String selectedCity = 'All Cities (Penang)',
    String searchQuery = '',
  }) async {
    purgeLegacySampleClinicsFromFirestore();
    final snapshot = await _db.collection('CLINICS').get();
    final clinics = snapshot.docs
        .where((doc) => !legacySampleIds.contains(doc.id) && !legacySampleIds.contains(doc.id.toLowerCase()))
        .map((doc) => ClinicModel.fromMap(doc.data(), doc.id))
        .toList();
    return processClinicsList(
      clinics,
      userLat: userLat,
      userLng: userLng,
      selectedCity: selectedCity,
      searchQuery: searchQuery,
    );
  }

  /// Direct Google Maps launcher specifically directing to the exact vet place
  Future<bool> openGoogleMaps({
    required String clinicName,
    String address = 'Penang, Malaysia',
    required double latitude,
    required double longitude,
    String? googleMapsUrl,
  }) async {
    if (googleMapsUrl != null && googleMapsUrl.trim().isNotEmpty && googleMapsUrl.startsWith('http')) {
      final Uri customUri = Uri.parse(googleMapsUrl.trim());
      try {
        if (await canLaunchUrl(customUri)) {
          return await launchUrl(customUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }

    final String fullQuery = Uri.encodeComponent('$clinicName $address');
    final String placeQuery = Uri.encodeComponent('$clinicName Penang');

    // 1. Direct Place Search Query on Google Maps
    final Uri defaultMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$fullQuery',
    );

    // 2. Direct Turn-by-Turn Directions URL
    final Uri directionsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$placeQuery&destination_place_id=$latitude,$longitude',
    );

    // 3. Native Geo URI Scheme for Mobile Devices
    final Uri geoUrl = Uri.parse(
      'geo:$latitude,$longitude?q=$placeQuery',
    );

    try {
      if (await canLaunchUrl(defaultMapsUrl)) {
        return await launchUrl(defaultMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(directionsUrl)) {
        return await launchUrl(directionsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(geoUrl)) {
        return await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(defaultMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error opening Google Maps: $e");
      return false;
    }
  }

  /// Sanitize string for Firestore document ID key
  String _slugify(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }

  /// Create booking atomically using a Firestore Transaction to guarantee
  /// that even if two users click "Confirm" within 0.001 seconds, only the
  /// faster user gets the slot, while the slower user receives an error.
  Future<String> createBookingWithAtomicLock(BookingModel booking) async {
    final String dateKey = DateFormat('yyyy-MM-dd').format(booking.bookingDate);
    final String slotKey = _slugify(booking.timeSlot);
    final String vetKey = _slugify(booking.preferredVet);

    final bool isAnyVet = vetKey.contains('any') || vetKey.startsWith('--') || vetKey.isEmpty;

    final String specificLockDocId = '${booking.clinicId}_${dateKey}_${vetKey}_$slotKey';
    final String anyVetLockDocId = '${booking.clinicId}_${dateKey}_any_vet_$slotKey';

    final DocumentReference specificLockRef = _db.collection('CLINIC_SLOT_LOCKS').doc(specificLockDocId);
    final DocumentReference anyVetLockRef = _db.collection('CLINIC_SLOT_LOCKS').doc(anyVetLockDocId);

    final DocumentReference userBookingRef = _db
        .collection('USERS')
        .doc(booking.userId)
        .collection('BOOKINGS')
        .doc(); // Auto-generate ID

    await _db.runTransaction((transaction) async {
      // 1. Read existing lock documents atomically
      final DocumentSnapshot specificLockSnap = await transaction.get(specificLockRef);
      final DocumentSnapshot anyVetLockSnap = await transaction.get(anyVetLockRef);

      // 2. Check for conflicts
      if (specificLockSnap.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'already-exists',
          message: 'Sorry! This time slot for ${booking.preferredVet} was just booked by another user. Please select another time slot or day.',
        );
      }

      if (anyVetLockSnap.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'already-exists',
          message: 'Sorry! This time slot at ${booking.clinicName} was just booked by another user. Please select another time slot or day.',
        );
      }

      // 3. Write atomic locks
      final Map<String, dynamic> lockData = {
        'clinicId': booking.clinicId,
        'bookingDate': dateKey,
        'timeSlot': booking.timeSlot,
        'preferredVet': booking.preferredVet,
        'userId': booking.userId,
        'bookingId': userBookingRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      };

      transaction.set(specificLockRef, lockData);
      if (!isAnyVet) {
        transaction.set(anyVetLockRef, lockData);
      }

      // 4. Create the booking document
      transaction.set(userBookingRef, booking.toMap());
    });

    return userBookingRef.id;
  }

  /// Save booking to Firestore under `USERS/{userId}/BOOKINGS`
  Future<String> createBooking(BookingModel booking) async {
    return createBookingWithAtomicLock(booking);
  }

  /// Stream active and past bookings for a user
  Stream<List<BookingModel>> streamUserBookings(String userId) {
    return _db
        .collection('USERS')
        .doc(userId)
        .collection('BOOKINGS')
        .orderBy('bookingDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream all bookings across all users
  Stream<List<BookingModel>> streamAllBookings() {
    return _db
        .collectionGroup('BOOKINGS')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
          return list;
        });
  }

  /// Stream bookings strictly for a specific Vet clinic (filtered by vetUid, clinicName, or vetEmail)
  Stream<List<BookingModel>> streamVetClinicBookings(String vetUid, String clinicName, {String? vetEmail}) {
    return _db
        .collectionGroup('BOOKINGS')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .where((b) {
                // 1. Direct match on clinicId
                if (vetUid.isNotEmpty && b.clinicId == vetUid) return true;

                // 2. Direct match on clinicName (case insensitive)
                if (clinicName.isNotEmpty &&
                    b.clinicName.trim().toLowerCase() == clinicName.trim().toLowerCase()) {
                  return true;
                }

                // 3. Match on vet email if present
                if (vetEmail != null && vetEmail.isNotEmpty) {
                  final e = vetEmail.trim().toLowerCase();
                  if (b.clinicAddress.toLowerCase().contains(e) ||
                      b.clinicName.toLowerCase().contains(e)) {
                    return true;
                  }
                }

                return false;
              })
              .toList();
          list.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
          return list;
        });
  }

  /// Updates booking status (e.g. 'PENDING' -> 'CONFIRMED', 'CANCELLED', 'COMPLETED')
  Future<void> updateBookingStatus(String userId, String bookingId, String newStatus) async {
    await _db
        .collection('USERS')
        .doc(userId)
        .collection('BOOKINGS')
        .doc(bookingId)
        .update({'status': newStatus.toUpperCase()});

    if (newStatus.toUpperCase() == 'CANCELLED') {
      await _releaseBookingLock(userId, bookingId);
    }
  }

  /// Cancel a booking in Firestore
  Future<void> cancelBooking(String userId, String bookingId) async {
    await updateBookingStatus(userId, bookingId, 'CANCELLED');
  }

  /// Stream active (PENDING or CONFIRMED) bookings for a specific clinic to lock time slots
  Stream<List<BookingModel>> streamClinicActiveBookings(String clinicId) {
    return _db
        .collectionGroup('BOOKINGS')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
            .where((b) =>
                b.clinicId == clinicId &&
                (b.status.toUpperCase() == 'PENDING' || b.status.toUpperCase() == 'CONFIRMED'))
            .toList());
  }

  /// Permanently delete a booking record from Firestore
  Future<void> deleteBooking(String userId, String bookingId) async {
    await _releaseBookingLock(userId, bookingId);
    await _db
        .collection('USERS')
        .doc(userId)
        .collection('BOOKINGS')
        .doc(bookingId)
        .delete();
  }

  Future<void> _releaseBookingLock(String userId, String bookingId) async {
    try {
      final locks = await _db
          .collection('CLINIC_SLOT_LOCKS')
          .where('bookingId', isEqualTo: bookingId)
          .get();

      for (final doc in locks.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint("Error releasing lock for booking $bookingId: $e");
    }
  }
}
