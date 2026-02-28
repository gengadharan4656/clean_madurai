import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Reusable button widget to open the map screen.
/// Use this in citizen dashboard + collector dashboard.
class FindNearbyDustbinButton extends StatelessWidget {
  final String title;
  final String subtitle;

  const FindNearbyDustbinButton({
    super.key,
    this.title = 'Find Nearby Dustbin',
    this.subtitle = 'Shows dustbins in Madurai on map + top 3 nearest',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DustbinMapScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline, color: Color(0xFF1B5E20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

/// Full screen with free map + markers + top 3 nearest
class DustbinMapScreen extends StatefulWidget {
  const DustbinMapScreen({super.key});

  @override
  State<DustbinMapScreen> createState() => _DustbinMapScreenState();
}

class _DustbinMapScreenState extends State<DustbinMapScreen> {
  bool _loading = true;
  String? _error;

  LatLng? _user;
  List<DustbinPoint> _bins = [];
  List<NearestDustbin> _nearest = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final pos = await _getLocation();
      _user = LatLng(pos.latitude, pos.longitude);

      // Fetch bins from Overpass (Madurai area)
      _bins = await OverpassDustbinService.fetchMaduraiBins();

      // compute nearest 3
      _nearest = _getNearestBins(_user!, _bins, topN: 3);

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<Position> _getLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nearby Dustbins')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error: $_error\n\nTip: Check internet + location permission.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final user = _user!;
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Dustbins (Madurai)')),
      body: Column(
        children: [
          // Top 3 nearest
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top 3 Nearest',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                if (_nearest.isEmpty)
                  const Text('No dustbins found in OSM for this area.')
                else
                  Column(
                    children: _nearest.map((n) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.delete, size: 20),
                        title: Text(n.title),
                        subtitle: Text('${n.distanceMeters.round()} meters away'),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          // Free map
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: user,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.cleanmadurai.app',
                ),
                MarkerLayer(
                  markers: [
                    // user marker
                    Marker(
                      point: user,
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.my_location, size: 34),
                    ),

                    // dustbin markers
                    ..._bins.map((b) {
                      return Marker(
                        point: LatLng(b.lat, b.lng),
                        width: 44,
                        height: 44,
                        child: const Icon(Icons.delete_outline, size: 30),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<NearestDustbin> _getNearestBins(
      LatLng user,
      List<DustbinPoint> bins, {
        int topN = 3,
      }) {
    final list = bins.map((b) {
      final d = _haversineMeters(user.latitude, user.longitude, b.lat, b.lng);
      return NearestDustbin(
        title: b.name ?? b.amenityLabel,
        distanceMeters: d,
        bin: b,
      );
    }).toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    return list.take(topN).toList();
  }

  // Haversine distance in meters
  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Earth radius meters
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double d) => d * (pi / 180.0);
}

/// Dustbin point model
class DustbinPoint {
  final double lat;
  final double lng;
  final String amenity; // waste_basket / waste_disposal
  final String? name;

  DustbinPoint({
    required this.lat,
    required this.lng,
    required this.amenity,
    this.name,
  });

  String get amenityLabel =>
      amenity == 'waste_disposal' ? 'Waste Disposal' : 'Waste Basket';
}

class NearestDustbin {
  final String title;
  final double distanceMeters;
  final DustbinPoint bin;

  NearestDustbin({
    required this.title,
    required this.distanceMeters,
    required this.bin,
  });
}

/// Overpass API service (Madurai only)
class OverpassDustbinService {
  static const _endpoint = 'https://overpass-api.de/api/interpreter';

  /// Fetches waste baskets + waste disposal points inside "Madurai" admin area.
  static Future<List<DustbinPoint>> fetchMaduraiBins() async {
    const query = r'''
[out:json][timeout:25];
area["name"="Madurai"]["boundary"="administrative"]->.a;
(
  node["amenity"="waste_basket"](area.a);
  node["amenity"="waste_disposal"](area.a);
  way["amenity"="waste_basket"](area.a);
  way["amenity"="waste_disposal"](area.a);
  relation["amenity"="waste_basket"](area.a);
  relation["amenity"="waste_disposal"](area.a);
);
out center tags;
''';

    final res = await http.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'data': query},
    );

    if (res.statusCode != 200) {
      throw Exception('Overpass failed: ${res.statusCode}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final elements = (json['elements'] as List).cast<Map<String, dynamic>>();

    final out = <DustbinPoint>[];

    for (final e in elements) {
      double? lat = (e['lat'] as num?)?.toDouble();
      double? lon = (e['lon'] as num?)?.toDouble();

      // ways/relations provide center
      if (lat == null || lon == null) {
        final center = e['center'];
        if (center is Map<String, dynamic>) {
          lat = (center['lat'] as num?)?.toDouble();
          lon = (center['lon'] as num?)?.toDouble();
        }
      }
      if (lat == null || lon == null) continue;

      final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? {};
      final amenity = (tags['amenity'] as String?) ?? '';
      if (amenity != 'waste_basket' && amenity != 'waste_disposal') continue;

      out.add(DustbinPoint(
        lat: lat,
        lng: lon,
        amenity: amenity,
        name: tags['name'] as String?,
      ));
    }

    return out;
  }
}