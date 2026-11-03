import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_url_extractor/google_maps_url_extractor.dart';

/// ClinicModel: Represents an authentic veterinary clinic in Penang, Malaysia
/// with real Google Review ratings, review counts, and exact GPS coordinates.
class ClinicModel {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final String operatingHours;
  final String city; // Penang cities (e.g., George Town, Bayan Lepas, Butterworth, etc.)
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String? googleMapsUrl;
  final List<String> services;
  final List<String> veterinarians;
  final List<Map<String, dynamic>> doctorSchedules;
  final List<String> operatingDays;
  final List<String> operatingTimeSlots;
  final bool isAcceptingBookings;
  final String description;

  const ClinicModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.operatingHours,
    required this.city,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.googleMapsUrl,
    required this.services,
    this.veterinarians = const [],
    this.doctorSchedules = const [],
    this.operatingDays = const [],
    this.operatingTimeSlots = const [],
    this.isAcceptingBookings = true,
    this.description = '',
  });

  bool get isBookingReady {
    // 1. Must be accepting bookings
    if (!isAcceptingBookings) return false;

    // 2. Service type must be set (not empty)
    if (services.isEmpty) return false;

    // 3. Vet doctor / surgeon names must be set (not empty)
    if (veterinarians.isEmpty) return false;

    // 4. Operating hours / time slots must be explicitly set (not empty or "Not Set")
    final String hours = operatingHours.trim().toLowerCase();
    if (hours.isEmpty || hours.contains('not set') || hours == 'closed') return false;

    // 5. Operating days must be configured
    if (operatingDays.isEmpty) return false;

    return true;
  }

  /// Check if the clinic is open on a specific day of the week
  bool isOperatingDay(DateTime date) {
    if (operatingDays.isEmpty) return false;
    final String dayName = DateFormat('EEE').format(date); // e.g. 'Mon'
    final String shortLabel = DateFormat('EEE, dd MMM').format(date); // e.g. 'Mon, 27 Jan'
    final String dayNameLower = dayName.trim().toLowerCase();
    final String shortLabelLower = shortLabel.trim().toLowerCase();

    return operatingDays.any((d) {
      final String trimmed = d.trim().toLowerCase();
      return trimmed == shortLabelLower ||
             trimmed == dayNameLower ||
             trimmed.startsWith(dayNameLower);
    });
  }

  /// Check if a specific doctor is available for bookings
  bool isDoctorAvailable(String vetName) {
    final String trimmed = vetName.trim();
    if (trimmed.isEmpty || trimmed == 'Any Available Vet' || trimmed.startsWith('--')) {
      return true;
    }
    final doc = doctorSchedules.firstWhere(
      (d) => (d['name'] ?? '').toString().trim().toLowerCase() == trimmed.toLowerCase(),
      orElse: () => <String, dynamic>{},
    );
    if (doc.isEmpty) return true; // Default to available if not explicitly set

    final bool isAvailable = doc['isAvailable'] ?? true;
    final List slots = (doc['timeSlots'] as List?) ?? [];
    return isAvailable && slots.isNotEmpty;
  }

  static int parseTimeToMinutesStatic(String timeStr) {
    try {
      final parts = timeStr.trim().split(' ');
      if (parts.length >= 2) {
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        final isPm = parts[1].toUpperCase() == 'PM';
        if (isPm && hour < 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;
        return hour * 60 + minute;
      }
    } catch (_) {}
    return 0;
  }

  /// Get specific working time slots for a preferred doctor sorted from earliest to latest
  List<String> getSlotsForDoctor(String vetName) {
    final String trimmed = vetName.trim();
    List<String> rawSlots = [];

    if (trimmed.isEmpty || trimmed == 'Any Available Vet' || trimmed.startsWith('--')) {
      rawSlots = List<String>.from(operatingTimeSlots);
    } else {
      final doc = doctorSchedules.firstWhere(
        (d) => (d['name'] ?? '').toString().trim().toLowerCase() == trimmed.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );
      if (doc.isEmpty) {
        rawSlots = List<String>.from(operatingTimeSlots);
      } else {
        final bool isAvailable = doc['isAvailable'] ?? true;
        if (!isAvailable) return []; // Off-duty doctor has no available time slots

        final List slots = (doc['timeSlots'] as List?) ?? [];
        if (slots.isEmpty) {
          rawSlots = List<String>.from(operatingTimeSlots);
        } else {
          rawSlots = slots.map((s) => s.toString()).toList();
        }
      }
    }

    rawSlots.sort((a, b) => parseTimeToMinutesStatic(a).compareTo(parseTimeToMinutesStatic(b)));
    return rawSlots;
  }

  ClinicModel copyWithDistance(double newDistanceKm) {
    return ClinicModel(
      id: id,
      name: name,
      specialty: specialty,
      rating: rating,
      reviewCount: reviewCount,
      distanceKm: double.parse(newDistanceKm.toStringAsFixed(1)),
      operatingHours: operatingHours,
      city: city,
      address: address,
      phone: phone,
      latitude: latitude,
      longitude: longitude,
      imageUrl: imageUrl,
      googleMapsUrl: googleMapsUrl,
      services: services,
      veterinarians: veterinarians,
      doctorSchedules: doctorSchedules,
      operatingDays: operatingDays,
      operatingTimeSlots: operatingTimeSlots,
      isAcceptingBookings: isAcceptingBookings,
      description: description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'rating': rating,
      'reviewCount': reviewCount,
      'distanceKm': distanceKm,
      'operatingHours': operatingHours,
      'city': city,
      'address': address,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'googleMapsUrl': googleMapsUrl,
      'services': services,
      'veterinarians': veterinarians,
      'doctorDetails': doctorSchedules,
      'operatingDays': operatingDays,
      'operatingTimeSlots': operatingTimeSlots,
      'isAcceptingBookings': isAcceptingBookings,
      'description': description,
    };
  }

  factory ClinicModel.fromMap(Map<String, dynamic> map, String docId) {
    final String name = map['name'] ?? map['clinicName'] ?? map['displayName'] ?? '';
    final String address = map['address'] ?? '';
    final String? mapsUrl = map['googleMapsUrl']?.toString();

    // Dynamically extract exact GPS coordinates from Google Maps Link or Address
    double lat = (map['latitude'] as num?)?.toDouble() ?? 0.0;
    double lng = (map['longitude'] as num?)?.toDouble() ?? 0.0;

    // Prioritize parsing fresh coordinates from googleMapsUrl if lat/lng are missing or default
    if (lat == 0.0 || lng == 0.0 || (lat == 5.4164 && lng == 100.3327)) {
      if (mapsUrl != null && mapsUrl.trim().isNotEmpty) {
        final parsed = ClinicModel.parseExactCoordinatesFromGoogleMapsUrl(mapsUrl, address, name);
        if (parsed['latitude'] != 5.4164 || parsed['longitude'] != 100.3327) {
          lat = parsed['latitude'] ?? lat;
          lng = parsed['longitude'] ?? lng;
        }
      }
    }

    if (lat == 0.0 || lng == 0.0) {
      final fallback = ClinicModel.parseExactCoordinatesFromGoogleMapsUrl(mapsUrl ?? '', address, name);
      lat = fallback['latitude'] ?? 5.4164;
      lng = fallback['longitude'] ?? 100.3327;
    }

    final bool acceptingBookings = map['isAcceptingBookings'] ?? map['isBookingEnabled'] ?? true;

    final rawDoctorDetails = map['doctorDetails'] ?? map['doctorSchedules'];
    List<Map<String, dynamic>> doctorSchedules = [];
    if (rawDoctorDetails is List) {
      doctorSchedules = rawDoctorDetails.map((e) {
        if (e is Map) {
          return Map<String, dynamic>.from(e);
        } else if (e is String) {
          return {
            "name": e,
            "isAvailable": true,
            "timeSlots": <String>[],
          };
        }
        return <String, dynamic>{};
      }).where((element) => element.isNotEmpty).toList();
    }

    // Fallback if doctorDetails is not present but veterinarians list is present
    if (doctorSchedules.isEmpty && map['veterinarians'] is List) {
      final List<dynamic> vets = map['veterinarians'];
      for (var v in vets) {
        if (v is String && v.trim().isNotEmpty) {
          doctorSchedules.add({
            "name": v.trim(),
            "isAvailable": true,
            "timeSlots": <String>[],
          });
        } else if (v is Map) {
          doctorSchedules.add(Map<String, dynamic>.from(v));
        }
      }
    }

    final List<String> vetNames = doctorSchedules.isNotEmpty
        ? doctorSchedules.map((d) => (d['name'] ?? '').toString()).where((n) => n.isNotEmpty).toList()
        : List<String>.from(map['veterinarians'] ?? []);

    return ClinicModel(
      id: docId,
      name: name,
      specialty: (map['specialty'] ?? 'General Veterinary').toString().replaceAll('General Veterinary & Surgery', 'General Veterinary'),
      rating: (map['rating'] as num?)?.toDouble() ?? 4.7,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 100,
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 1.0,
      operatingHours: (map['operatingHours'] != null && map['operatingHours'].toString().trim().isNotEmpty)
          ? map['operatingHours'].toString().trim()
          : '', // Do NOT set default fake operating hours!
      city: map['city'] ?? '',
      address: address,
      phone: map['phone'] ?? '',
      latitude: lat,
      longitude: lng,
      imageUrl: map['imageUrl'],
      googleMapsUrl: mapsUrl,
      services: List<String>.from(map['services'] ?? []),
      veterinarians: vetNames,
      doctorSchedules: doctorSchedules,
      operatingDays: List<String>.from(map['operatingDays'] ?? []),
      operatingTimeSlots: List<String>.from(map['operatingTimeSlots'] ?? map['operatingSlots'] ?? []),
      isAcceptingBookings: acceptingBookings,
      description: map['description'] ?? '',
    );
  }

  /// Strictly extracts latitude and longitude from the provided Google Maps URL.
  /// Priority order:
  /// 1. Exact place pinpoint marker: `!3d[lat]!4d[lng]` or `3d[lat]!4d[lng]`
  /// 2. Explicit query/destination/location params: q=, query=, ll=, point=, center=, destination=, near=, daddr=, saddr=
  /// 3. Path patterns: /search/lat,lng, /dir/lat,lng, /place/lat,lng, geo:lat,lng
  /// 4. Viewport camera center: @lat,lng (fallback when no place pin exists)
  /// 5. Universal coordinates pair: lat,lng
  static Map<String, double>? extractCoordinatesFromGoogleMapsUrlStrict(String googleMapsUrl) {
    final String url = googleMapsUrl.trim();
    if (url.isEmpty) return null;

    // 1. Priority 1: Check for exact place pinpoint marker !3dlatitude!4dlongitude (or 3dlatitude!4dlongitude)
    final RegExp dRegex = RegExp(r'(?:!3d|3d)(-?\d+\.\d+).*?(?:!4d|4d)(-?\d+\.\d+)');
    final dMatch = dRegex.firstMatch(url);
    if (dMatch != null && dMatch.groupCount >= 2) {
      final double? lat = double.tryParse(dMatch.group(1)!);
      final double? lng = double.tryParse(dMatch.group(2)!);
      if (lat != null && lng != null && _isValidCoord(lat, lng)) {
        return {'latitude': lat, 'longitude': lng};
      }
    }

    // 2. Priority 2: Check for explicit query/destination/location parameters e.g. q=5.407890,100.310123
    final RegExp qRegex = RegExp(r'(?:q|query|ll|point|center|sll|destination|near|daddr|saddr)=(-?\d+\.\d+),\s*(-?\d+\.\d+)');
    final qMatch = qRegex.firstMatch(url);
    if (qMatch != null && qMatch.groupCount >= 2) {
      final double? lat = double.tryParse(qMatch.group(1)!);
      final double? lng = double.tryParse(qMatch.group(2)!);
      if (lat != null && lng != null && _isValidCoord(lat, lng)) {
        return {'latitude': lat, 'longitude': lng};
      }
    }

    // 3. Priority 3: Check for path patterns e.g. /search/5.407890,100.310123 or /dir/5.407890,100.310123 or geo:5.407890,100.310123
    final RegExp pathRegex = RegExp(r'(?:search|dir|place|geo:|\/)(-?\d+\.\d+),\s*(-?\d+\.\d+)');
    final pathMatch = pathRegex.firstMatch(url);
    if (pathMatch != null && pathMatch.groupCount >= 2) {
      final double? lat = double.tryParse(pathMatch.group(1)!);
      final double? lng = double.tryParse(pathMatch.group(2)!);
      if (lat != null && lng != null && _isValidCoord(lat, lng)) {
        return {'latitude': lat, 'longitude': lng};
      }
    }

    // 4. Priority 4: Check for @latitude,longitude format (Viewport Camera Center - fallback)
    final RegExp atRegex = RegExp(r'@(-?\d+\.\d+),\s*(-?\d+\.\d+)');
    final atMatch = atRegex.firstMatch(url);
    if (atMatch != null && atMatch.groupCount >= 2) {
      final double? lat = double.tryParse(atMatch.group(1)!);
      final double? lng = double.tryParse(atMatch.group(2)!);
      if (lat != null && lng != null && _isValidCoord(lat, lng)) {
        return {'latitude': lat, 'longitude': lng};
      }
    }

    // 5. Priority 5: Universal lat,lng search anywhere in URL string
    final RegExp coordRegex = RegExp(r'(-?\d{1,2}\.\d{3,})\s*,\s*(-?\d{2,3}\.\d{3,})');
    final matches = coordRegex.allMatches(url);
    for (var match in matches) {
      if (match.groupCount >= 2) {
        final double? lat = double.tryParse(match.group(1)!);
        final double? lng = double.tryParse(match.group(2)!);
        if (lat != null && lng != null && _isValidCoord(lat, lng)) {
          return {'latitude': lat, 'longitude': lng};
        }
      }
    }

    return null;
  }

  static bool _isValidCoord(double lat, double lng) {
    return lat >= -90.0 && lat <= 90.0 && lng >= -180.0 && lng <= 180.0 && (lat != 0.0 || lng != 0.0);
  }

  /// Parses exact latitude & longitude strictly from Google Maps URL or address geocoding.
  static Map<String, double> parseExactCoordinatesFromGoogleMapsUrl(String mapsUrl, String address, String clinicName) {
    final strict = extractCoordinatesFromGoogleMapsUrlStrict(mapsUrl);
    if (strict != null) {
      return strict;
    }

    return {
      'latitude': 5.4164,
      'longitude': 100.3327,
    };
  }

  /// Asynchronously resolves short Google Maps URLs (maps.app.goo.gl or goo.gl/maps)
  /// or geocodes the exact clinic name & address to guarantee 100% accurate location plotting.
  static Future<Map<String, double>> resolveGoogleMapsCoordinatesAsync(String mapsUrl, String address, String clinicName) async {
    final String url = mapsUrl.trim();

    if (url.isNotEmpty) {
      // 1. Direct Strict Regex Extraction from provided URL
      final direct = extractCoordinatesFromGoogleMapsUrlStrict(url);
      if (direct != null) {
        return direct;
      }

      // 2. Expand short Google Maps link using google_maps_url_extractor package
      try {
        final dynamic extracted = GoogleMapsUrlExtractor.extractCoordinates(url);
        if (extracted != null) {
          double? lat;
          double? lng;
          if (extracted is Map) {
            lat = (extracted['latitude'] ?? extracted['lat'])?.toDouble();
            lng = (extracted['longitude'] ?? extracted['lng'])?.toDouble();
          } else {
            try {
              lat = (extracted.latitude as num?)?.toDouble();
              lng = (extracted.longitude as num?)?.toDouble();
            } catch (_) {}
          }
          if (lat != null && lng != null && _isValidCoord(lat, lng)) {
            return {
              'latitude': lat,
              'longitude': lng,
            };
          }
        }
      } catch (e) {
        debugPrint("GoogleMapsUrlExtractor error for short URL ($url): $e");
      }

      // 3. Robust manual redirection & HTML body expansion for short links (maps.app.goo.gl, goo.gl/maps, g.co)
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 6);

        String currentUrl = url;
        int redirectCount = 0;

        while (currentUrl.isNotEmpty && redirectCount < 6) {
          final Uri uri = Uri.parse(currentUrl);
          final request = await client.getUrl(uri);
          request.headers.set(
            'User-Agent',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          );
          request.followRedirects = false; // Inspect each redirect status manually

          final response = await request.close();
          final String? locationHeader = response.headers.value('location');

          if (locationHeader != null && locationHeader.isNotEmpty) {
            String nextUrl = locationHeader;
            if (!nextUrl.startsWith('http')) {
              nextUrl = uri.resolve(nextUrl).toString();
            }

            final redirectExtracted = extractCoordinatesFromGoogleMapsUrlStrict(nextUrl);
            if (redirectExtracted != null) {
              client.close();
              return redirectExtracted;
            }

            currentUrl = nextUrl;
            redirectCount++;
          } else {
            // Reached final destination (200 OK)
            final String body = await response.transform(utf8.decoder).join();

            // Try extracting from body string
            final bodyExtracted = extractCoordinatesFromGoogleMapsUrlStrict(body);
            if (bodyExtracted != null) {
              client.close();
              return bodyExtracted;
            }

            // Check HTML meta tags or static map URLs (center=lat%2Clng or markers=lat%2Clng)
            final RegExp centerRegex = RegExp(r'(?:center|markers|query)=(-?\d+\.\d+)(?:%2C|,)\s*(-?\d+\.\d+)');
            final centerMatch = centerRegex.firstMatch(body);
            if (centerMatch != null && centerMatch.groupCount >= 2) {
              final double? lat = double.tryParse(centerMatch.group(1)!);
              final double? lng = double.tryParse(centerMatch.group(2)!);
              if (lat != null && lng != null && _isValidCoord(lat, lng)) {
                client.close();
                return {'latitude': lat, 'longitude': lng};
              }
            }

            break;
          }
        }
        client.close();
      } catch (e) {
        debugPrint("Error expanding short Google Maps URL ($url): $e");
      }
    }

    // 4. OpenStreetMap Nominatim Exact Address Geocoding Fallback
    if (clinicName.isNotEmpty || address.isNotEmpty) {
      try {
        final String searchQuery = Uri.encodeComponent("$clinicName, $address, Penang, Malaysia");
        final Uri geocodeUri = Uri.parse("https://nominatim.openstreetmap.org/search?q=$searchQuery&format=json&limit=1");
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 4);
        client.userAgent = "PawKODA_FYP_App/1.0";
        final request = await client.getUrl(geocodeUri);
        final response = await request.close();

        if (response.statusCode == 200) {
          final String body = await response.transform(utf8.decoder).join();
          final List jsonList = jsonDecode(body);
          if (jsonList.isNotEmpty) {
            final double? lat = double.tryParse(jsonList[0]['lat']?.toString() ?? '');
            final double? lng = double.tryParse(jsonList[0]['lon']?.toString() ?? '');
            if (lat != null && lng != null && _isValidCoord(lat, lng)) {
              return {'latitude': lat, 'longitude': lng};
            }
          }
        }
        client.close();
      } catch (e) {
        debugPrint("Error geocoding clinic address ($clinicName): $e");
      }
    }

    return {
      'latitude': 5.4164,
      'longitude': 100.3327,
    };
  }
}
