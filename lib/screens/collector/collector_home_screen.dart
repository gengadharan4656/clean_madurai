import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../services/user_service.dart';
import '../clean_route/clean_route_screen.dart';
import '../waste_guidance/waste_guidance_screen.dart';
import '../public_board/public_board_screen.dart';

class CollectorHomeScreen extends StatefulWidget {
  const CollectorHomeScreen({super.key});

  @override
  State<CollectorHomeScreen> createState() => _CollectorHomeScreenState();
}

class _CollectorHomeScreenState extends State<CollectorHomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = const [
      _CollectorQueueTab(),
      _NearbyMapTab(),
      _CollectorRouteTab(),
      _CollectorProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (v) => setState(() => _index = v),
        selectedItemColor: const Color(0xFF1B5E20),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Queue'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Near Me'),
          BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Route'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _CollectorQueueTab extends StatelessWidget {
  const _CollectorQueueTab();

  @override
  Widget build(BuildContext context) {
    final userSvc = context.read<UserService>();
    final complaintSvc = context.read<ComplaintService>();
    return StreamBuilder<UserModel?>(
      stream: userSvc.userStream,
      builder: (context, userSnap) {
        final ward = userSnap.data?.ward ?? 'Ward 1';
        return Scaffold(
          appBar: AppBar(
            title: Text('Collector Queue • $ward'),
            actions: [
              IconButton(
                icon: const Icon(Icons.public),
                tooltip: 'Public Board',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PublicBoardScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.recycling),
                tooltip: 'Waste Guide',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WasteGuidanceScreen()),
                ),
              ),
            ],
          ),
          body: StreamBuilder<List<ComplaintModel>>(
            stream: complaintSvc.collectorWardQueue(ward),
            builder: (context, snap) {
              final list = snap.data ?? [];
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (list.isEmpty) {
                return const Center(
                    child: Text('No pending complaints in your ward.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                itemBuilder: (_, i) =>
                    _CollectorComplaintCard(c: list[i]),
              );
            },
          ),
        );
      },
    );
  }
}

class _CollectorComplaintCard extends StatefulWidget {
  final ComplaintModel c;
  const _CollectorComplaintCard({required this.c});

  @override
  State<_CollectorComplaintCard> createState() =>
      _CollectorComplaintCardState();
}

class _CollectorComplaintCardState extends State<_CollectorComplaintCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${c.category} • #${c.id}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('Status: ${c.status.replaceAll('_', ' ')}'),
            Text(
                'Location: ${c.lat.toStringAsFixed(4)}, ${c.lng.toStringAsFixed(4)}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _busy ? null : () => _markStatus('in_progress'),
                    child: const Text('Start Work'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : _resolveWithAfterImage,
                    child: const Text('Resolve + After Photo'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _markStatus(String status) async {
    setState(() => _busy = true);
    final svc = context.read<ComplaintService>();
    final ok = await svc.collectorUpdateComplaint(
      complaintId: widget.c.id,
      status: status,
    );
    setState(() => _busy = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(ok
              ? 'Updated to $status'
              : (svc.lastError ?? 'Update failed'))),
    );
  }

  Future<void> _resolveWithAfterImage() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.camera, imageQuality: 80, maxWidth: 1080);
    if (picked == null) return;

    setState(() => _busy = true);
    final svc = context.read<ComplaintService>();
    final ok = await svc.collectorUpdateComplaint(
      complaintId: widget.c.id,
      status: 'resolved',
      afterImage: File(picked.path),
    );
    setState(() => _busy = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(ok
              ? 'Complaint resolved and photo uploaded'
              : (svc.lastError ?? 'Resolve failed'))),
    );
  }
}

class _NearbyMapTab extends StatefulWidget {
  const _NearbyMapTab();

  @override
  State<_NearbyMapTab> createState() => _NearbyMapTabState();
}

class _NearbyMapTabState extends State<_NearbyMapTab> {
  Position? _pos;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) return;
    final p = await Geolocator.getCurrentPosition();
    if (mounted) setState(() => _pos = p);
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Dustbin Near Me')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              value: _sharing,
              title: const Text('Share my live location'),
              subtitle: const Text(
                  'Used to notify citizens when collector is within 100m'),
              onChanged: (v) async {
                setState(() => _sharing = v);
                if (_pos == null || uid.isEmpty) return;
                await FirebaseFirestore.instance
                    .collection('worker_live')
                    .doc(uid)
                    .set({
                  'uid': uid,
                  'lat': _pos!.latitude,
                  'lng': _pos!.longitude,
                  'updatedAt': FieldValue.serverTimestamp(),
                  'sharing': v,
                }, SetOptions(merge: true));
              },
            ),
            const SizedBox(height: 8),
            const Text('Markers preview',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _markerCard(
                '📍 User marker',
                _pos == null
                    ? 'Unknown'
                    : '${_pos!.latitude.toStringAsFixed(4)}, ${_pos!.longitude.toStringAsFixed(4)}'),
            _markerCard(
                '🗑️ Dustbin markers', 'Load from `dustbins` collection'),
            _markerCard(
                '🚛 Worker live marker', 'From `worker_live` collection'),
            const SizedBox(height: 16),
            Expanded(
              child:
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('dustbins')
                    .limit(20)
                    .snapshots(),
                builder: (context, snap) {
                  final bins = snap.data?.docs ?? [];
                  if (bins.isEmpty) {
                    return const Center(
                        child: Text(
                            'No dustbin points found. Add docs in Firestore `dustbins` collection.'));
                  }
                  return ListView.builder(
                    itemCount: bins.length,
                    itemBuilder: (_, i) {
                      final d = bins[i].data();
                      final lat = (d['lat'] as num?)?.toDouble() ?? 0;
                      final lng = (d['lng'] as num?)?.toDouble() ?? 0;
                      final name = d['name'] ?? 'Dustbin ${i + 1}';
                      final distance = _pos == null
                          ? null
                          : Geolocator.distanceBetween(
                              _pos!.latitude,
                              _pos!.longitude,
                              lat,
                              lng);
                      return ListTile(
                        leading: const Text('🗑️'),
                        title: Text(name),
                        subtitle: Text(
                            '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'),
                        trailing: distance == null
                            ? null
                            : Text('${distance.round()} m',
                                style: TextStyle(
                                    color: distance <= 100
                                        ? Colors.green
                                        : Colors.grey)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _markerCard(String title, String subtitle) {
    return Card(
        child: ListTile(title: Text(title), subtitle: Text(subtitle)));
  }
}

// NEW: Route tab — wraps CleanRouteScreen with ward from user profile
class _CollectorRouteTab extends StatelessWidget {
  const _CollectorRouteTab();

  @override
  Widget build(BuildContext context) {
    final userSvc = context.read<UserService>();
    return StreamBuilder<UserModel?>(
      stream: userSvc.userStream,
      builder: (context, snap) {
        final ward = snap.data?.ward ?? 'Ward 1';
        return CleanRouteScreen(ward: ward);
      },
    );
  }
}

class _CollectorProfileTab extends StatelessWidget {
  const _CollectorProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final userSvc = context.read<UserService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Collector Profile')),
      body: StreamBuilder<UserModel?>(
        stream: userSvc.userStream,
        builder: (context, snap) {
          final u = snap.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                  title: const Text('Name'),
                  subtitle: Text(u?.name ?? '-')),
              ListTile(
                  title: const Text('Ward'),
                  subtitle: Text(u?.ward ?? '-')),
              ListTile(
                  title: const Text('Reward Points'),
                  subtitle:
                      Text('${u?.cleanlinessScore ?? 0}')),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async => auth.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          );
        },
      ),
    );
  }
}
