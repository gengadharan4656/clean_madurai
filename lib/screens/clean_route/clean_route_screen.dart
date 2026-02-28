// lib/screens/clean_route/clean_route_screen.dart
// NEW FILE – Today's suggested cleanup route (sorted list, no map routing)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class CleanRouteScreen extends StatefulWidget {
  final String ward;
  const CleanRouteScreen({super.key, required this.ward});

  @override
  State<CleanRouteScreen> createState() => _CleanRouteScreenState();
}

class _CleanRouteScreenState extends State<CleanRouteScreen> {
  Position? _pos;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _loadingLocation = false);
        return;
      }
      final p = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      if (mounted) setState(() {_pos = p; _loadingLocation = false;});
    } catch (_) {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Today's Route • ${widget.ward}"),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLocation,
            tooltip: 'Refresh location',
          )
        ],
      ),
      backgroundColor: const Color(0xFFF5F7F0),
      body: _loadingLocation
          ? const Center(child: CircularProgressIndicator())
          : _RouteList(ward: widget.ward, collectorPos: _pos),
    );
  }
}

const _priorityOrder = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};

class _RouteList extends StatelessWidget {
  final String ward;
  final Position? collectorPos;

  const _RouteList({required this.ward, this.collectorPos});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('ward', isEqualTo: ward)
          .where('status', whereIn: ['submitted', 'assigned', 'in_progress'])
          .orderBy('createdAt', descending: false)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎉', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('No pending complaints in your ward!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text('Great job keeping the ward clean.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        // Build route items with distance
        final items = docs.map((d) {
          final data = d.data();
          final loc = data['location'] as Map<String, dynamic>? ?? {};
          final lat = (loc['lat'] as num?)?.toDouble() ?? 9.9252;
          final lng = (loc['lng'] as num?)?.toDouble() ?? 78.1198;
          final priority = data['priority'] as String? ?? 'low';
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          final double? dist = collectorPos == null
              ? null
              : Geolocator.distanceBetween(
                  collectorPos!.latitude, collectorPos!.longitude, lat, lng);

          return _RouteItem(
            id: d.id,
            category: data['category'] as String? ?? 'Issue',
            description: data['description'] as String? ?? '',
            lat: lat,
            lng: lng,
            priority: priority,
            status: data['status'] as String? ?? 'submitted',
            createdAt: createdAt,
            distanceMeters: dist,
            stopNumber: 0,
          );
        }).toList();

        // Sort: priority → oldest first → distance
        items.sort((a, b) {
          final pa = _priorityOrder[a.priority] ?? 3;
          final pb = _priorityOrder[b.priority] ?? 3;
          if (pa != pb) return pa.compareTo(pb);
          if (a.createdAt != null && b.createdAt != null) {
            final c = a.createdAt!.compareTo(b.createdAt!);
            if (c != 0) return c;
          }
          if (a.distanceMeters != null && b.distanceMeters != null) {
            return a.distanceMeters!.compareTo(b.distanceMeters!);
          }
          return 0;
        });

        // Assign stop numbers
        for (var i = 0; i < items.length; i++) {
          items[i] = items[i].copyWithStop(i + 1);
        }

        return Column(
          children: [
            _RouteHeader(
              total: items.length,
              hasLocation: collectorPos != null,
            ),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: items.length,
                itemBuilder: (_, i) => _RouteCard(item: items[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RouteHeader extends StatelessWidget {
  final int total;
  final bool hasLocation;
  const _RouteHeader({required this.total, required this.hasLocation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$total stops',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasLocation
                  ? 'Sorted by priority, age & distance from you'
                  : 'Sorted by priority & complaint age',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          if (!hasLocation)
            const Icon(Icons.location_off, size: 16, color: Colors.orange),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final _RouteItem item;
  const _RouteCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final prColor = _priorityCardColor(item.priority);
    final prLabel = _priorityLabel(item.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stop number badge
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: prColor.withOpacity(0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${item.stopNumber}',
                  style: TextStyle(
                    color: prColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text('stop',
                    style:
                        TextStyle(fontSize: 9, color: prColor.withOpacity(0.7)),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_categoryEmoji(item.category)} ${item.category}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: prColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: prColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          prLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: prColor),
                        ),
                      ),
                    ],
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF555555)),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Chip(
                        icon: Icons.location_on,
                        label:
                            '${item.lat.toStringAsFixed(4)}, ${item.lng.toStringAsFixed(4)}',
                        color: Colors.grey.shade600,
                      ),
                      if (item.distanceMeters != null) ...[
                        const SizedBox(width: 8),
                        _Chip(
                          icon: Icons.directions_walk,
                          label: item.distanceMeters! < 1000
                              ? '${item.distanceMeters!.round()} m'
                              : '${(item.distanceMeters! / 1000).toStringAsFixed(1)} km',
                          color: item.distanceMeters! <= 200
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                        ),
                      ],
                      if (item.createdAt != null) ...[
                        const SizedBox(width: 8),
                        _Chip(
                          icon: Icons.access_time,
                          label: _timeAgo(item.createdAt!),
                          color: Colors.orange.shade700,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor(item.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _statusLabel(item.status),
                      style: TextStyle(
                          fontSize: 11,
                          color: _statusColor(item.status),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryEmoji(String cat) {
    switch (cat) {
      case 'Garbage Overflow': return '🗑️';
      case 'Open Dumping': return '⚠️';
      case 'Sewer Blockage': return '🚧';
      case 'Public Toilet Issue': return '🚽';
      default: return '📍';
    }
  }

  Color _priorityCardColor(String p) {
    switch (p) {
      case 'critical': return const Color(0xFFC62828);
      case 'high': return const Color(0xFFE65100);
      case 'medium': return const Color(0xFFF9A825);
      default: return const Color(0xFF388E3C);
    }
  }

  String _priorityLabel(String p) {
    switch (p) {
      case 'critical': return '🔴 Critical';
      case 'high': return '🟠 High';
      case 'medium': return '🟡 Medium';
      default: return '🟢 Low';
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'in_progress': return Colors.blue.shade700;
      case 'assigned': return Colors.purple.shade700;
      default: return Colors.grey.shade600;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'submitted': return '📤 Submitted';
      case 'assigned': return '👷 Assigned';
      case 'in_progress': return '🔧 In Progress';
      default: return s;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

class _RouteItem {
  final String id;
  final String category;
  final String description;
  final double lat;
  final double lng;
  final String priority;
  final String status;
  final DateTime? createdAt;
  final double? distanceMeters;
  final int stopNumber;

  const _RouteItem({
    required this.id,
    required this.category,
    required this.description,
    required this.lat,
    required this.lng,
    required this.priority,
    required this.status,
    this.createdAt,
    this.distanceMeters,
    required this.stopNumber,
  });

  _RouteItem copyWithStop(int stop) => _RouteItem(
        id: id,
        category: category,
        description: description,
        lat: lat,
        lng: lng,
        priority: priority,
        status: status,
        createdAt: createdAt,
        distanceMeters: distanceMeters,
        stopNumber: stop,
      );
}
