import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/dustbin_model.dart';

/// LocationService - FIXED version
/// Handles all location permissions and dustbin finding reliably
class LocationService {
  static Position? _lastKnownPosition;

  // ─────────────────────────────────────────────────────────────
  // GET CURRENT POSITION - FIXED with comprehensive permission handling
  // ─────────────────────────────────────────────────────────────
  static Future<Position?> getCurrentPosition({
    bool showPermissionDialog = true,
    BuildContext? context,
  }) async {
    try {
      // Step 1: Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context != null && showPermissionDialog) {
          await _showLocationServiceDialog(context);
        }
        // Try to get last known position as fallback
        return await Geolocator.getLastKnownPosition();
      }

      // Step 2: Check permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return _getDefaultMaduraiPosition();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context != null && showPermissionDialog) {
          await _showPermissionDeniedDialog(context);
        }
        return _getDefaultMaduraiPosition();
      }

      // Step 3: Get position with timeout and accuracy settings
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
        forceAndroidLocationManager: false,
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () async {
          debugPrint('Location timeout, trying last known');
          final last = await Geolocator.getLastKnownPosition();
          return last ?? _getDefaultMaduraiPosition();
        },
      );

      _lastKnownPosition = position;
      return position;
    } catch (e) {
      debugPrint('Location error: $e');
      // Return last known or default Madurai position
      return _lastKnownPosition ?? _getDefaultMaduraiPosition();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FIND DUSTBINS NEAR ME - FIXED
  // ─────────────────────────────────────────────────────────────
  static Future<List<DustbinModel>> findNearbyDustbins({
    required double latitude,
    required double longitude,
    double radiusKm = 2.0,
    int limit = 20,
  }) async {
    try {
      // In production: fetch from Firestore with geo queries
      // For now, using the pre-seeded Madurai dustbin locations
      final List<DustbinModel> allDustbins = _getMaduraiDustbins();

      // Filter by radius and sort by distance
      final List<DustbinModel> nearby = allDustbins
          .map((dustbin) {
            final double distance = _calculateDistance(
              latitude, longitude,
              dustbin.latitude, dustbin.longitude,
            );
            return dustbin.copyWith(distanceKm: distance);
          })
          .where((d) => d.distanceKm! <= radiusKm)
          .toList();

      // Sort by distance ascending
      nearby.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));

      return nearby.take(limit).toList();
    } catch (e) {
      debugPrint('Find dustbins error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────
  // GET ADDRESS FROM COORDINATES
  // ─────────────────────────────────────────────────────────────
  static Future<String> getAddressFromCoords(
      double lat, double lng) async {
    try {
      final List<Placemark> placemarks =
          await placemarkFromCoordinates(lat, lng)
              .timeout(const Duration(seconds: 10));

      if (placemarks.isEmpty) return 'Unknown Location';

      final Placemark place = placemarks.first;
      final parts = [
        place.street,
        place.subLocality,
        place.locality,
        place.postalCode,
      ].where((p) => p != null && p.isNotEmpty).toList();

      return parts.join(', ');
    } catch (e) {
      debugPrint('Geocoding error: $e');
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // STREAM POSITION UPDATES
  // ─────────────────────────────────────────────────────────────
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CALCULATE DISTANCE (Haversine formula)
  // ─────────────────────────────────────────────────────────────
  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) => degree * (pi / 180);

  // ─────────────────────────────────────────────────────────────
  // DEFAULT MADURAI DUSTBIN LOCATIONS (seeded data)
  // ─────────────────────────────────────────────────────────────
  static List<DustbinModel> _getMaduraiDustbins() {
    return [
      DustbinModel(
        id: 'db001', name: 'Meenakshi Amman Temple Entrance',
        latitude: 9.9195, longitude: 78.1193,
        ward: '1', type: 'public', capacity: 100,
        fillLevel: 45, isActive: true,
        address: 'East Masi St, Madurai',
      ),
      DustbinModel(
        id: 'db002', name: 'Bypass Road Corner',
        latitude: 9.9346, longitude: 78.1212,
        ward: '2', type: 'public', capacity: 200,
        fillLevel: 72, isActive: true,
        address: 'Bypass Road, Madurai',
      ),
      DustbinModel(
        id: 'db003', name: 'Periyar Bus Stand',
        latitude: 9.9197, longitude: 78.1215,
        ward: '3', type: 'large', capacity: 500,
        fillLevel: 88, isActive: true,
        address: 'Nehru St, Madurai',
      ),
      DustbinModel(
        id: 'db004', name: 'Anna Nagar Park',
        latitude: 9.9081, longitude: 78.1142,
        ward: '4', type: 'public', capacity: 150,
        fillLevel: 30, isActive: true,
        address: 'Anna Nagar, Madurai',
      ),
      DustbinModel(
        id: 'db005', name: 'KK Nagar Roundabout',
        latitude: 9.8987, longitude: 78.1026,
        ward: '5', type: 'public', capacity: 100,
        fillLevel: 60, isActive: true,
        address: 'KK Nagar, Madurai',
      ),
      DustbinModel(
        id: 'db006', name: 'Mattuthavani Bus Terminal',
        latitude: 9.9516, longitude: 78.1345,
        ward: '6', type: 'large', capacity: 500,
        fillLevel: 55, isActive: true,
        address: 'Mattuthavani, Madurai',
      ),
      DustbinModel(
        id: 'db007', name: 'Madurai Airport Road',
        latitude: 9.8346, longitude: 78.0933,
        ward: '7', type: 'public', capacity: 100,
        fillLevel: 25, isActive: true,
        address: 'Airport Road, Madurai',
      ),
      DustbinModel(
        id: 'db008', name: 'Samayanallur Market',
        latitude: 9.8892, longitude: 78.1456,
        ward: '8', type: 'market', capacity: 300,
        fillLevel: 90, isActive: true,
        address: 'Samayanallur, Madurai',
      ),
      DustbinModel(
        id: 'db009', name: 'Tallakulam Junction',
        latitude: 9.9369, longitude: 78.1081,
        ward: '9', type: 'public', capacity: 150,
        fillLevel: 42, isActive: true,
        address: 'Tallakulam, Madurai',
      ),
      DustbinModel(
        id: 'db010', name: 'Arappalayam',
        latitude: 9.9215, longitude: 78.0984,
        ward: '10', type: 'public', capacity: 200,
        fillLevel: 67, isActive: true,
        address: 'Arappalayam, Madurai',
      ),
      DustbinModel(
        id: 'db011', name: 'Vilangudi',
        latitude: 9.9672, longitude: 78.1234,
        ward: '11', type: 'public', capacity: 100,
        fillLevel: 35, isActive: true,
        address: 'Vilangudi, Madurai',
      ),
      DustbinModel(
        id: 'db012', name: 'Thirunagar Colony',
        latitude: 9.9134, longitude: 78.1056,
        ward: '12', type: 'residential', capacity: 150,
        fillLevel: 50, isActive: true,
        address: 'Thirunagar, Madurai',
      ),
      DustbinModel(
        id: 'db013', name: 'Teppakulam',
        latitude: 9.9246, longitude: 78.1256,
        ward: '1', type: 'public', capacity: 100,
        fillLevel: 20, isActive: true,
        address: 'Teppakulam, Madurai',
      ),
      DustbinModel(
        id: 'db014', name: 'Goripalayam',
        latitude: 9.9089, longitude: 78.1178,
        ward: '14', type: 'market', capacity: 300,
        fillLevel: 78, isActive: true,
        address: 'Goripalayam, Madurai',
      ),
      DustbinModel(
        id: 'db015', name: 'Sellur',
        latitude: 9.8976, longitude: 78.1234,
        ward: '15', type: 'public', capacity: 100,
        fillLevel: 44, isActive: true,
        address: 'Sellur, Madurai',
      ),
    ];
  }

  static Position _getDefaultMaduraiPosition() {
    return Position(
      latitude: 9.9252, longitude: 78.1198,
      timestamp: DateTime.now(),
      accuracy: 100, altitude: 0, altitudeAccuracy: 0,
      heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PERMISSION DIALOGS
  // ─────────────────────────────────────────────────────────────
  static Future<void> _showLocationServiceDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2419),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Location Required',
            style: TextStyle(color: Color(0xFFEEF4EE), fontWeight: FontWeight.w700)),
        content: const Text(
          'Please enable location services to find dustbins near you.',
          style: TextStyle(color: Color(0xFF8DA88D)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8DA88D))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2419),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Permission Denied',
            style: TextStyle(color: Color(0xFFEEF4EE), fontWeight: FontWeight.w700)),
        content: const Text(
          'Location permission is required to find nearby dustbins. Please grant it in app settings.',
          style: TextStyle(color: Color(0xFF8DA88D)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8DA88D))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await openAppSettings();
            },
            child: const Text('App Settings'),
          ),
        ],
      ),
    );
  }
}
