import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/complaint_service.dart';
import '../../services/user_service.dart';
import 'success_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  File? _image;
  String? _category;
  Position? _position;
  bool _gettingLoc = false;
  final _descCtrl = TextEditingController();

  final _categories = [
    {'v': 'Garbage Overflow', 'e': '🗑️'},
    {'v': 'Open Dumping', 'e': '♻️'},
    {'v': 'Sewer Blockage', 'e': '🚰'},
    {'v': 'Public Toilet Issue', 'e': '🚽'},
    {'v': 'Littering', 'e': '🍃'},
    {'v': 'Other', 'e': '📋'},
  ];

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() => _gettingLoc = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() => _gettingLoc = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      setState(() {
        _position = pos;
        _gettingLoc = false;
      });
    } catch (e) {
      setState(() => _gettingLoc = false);
    }
  }

  Future<void> _pickImage(ImageSource src) async {
    final picked = await ImagePicker()
        .pickImage(source: src, imageQuality: 80, maxWidth: 1080);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_image == null) {
      _snack('Please add a photo');
      return;
    }
    if (_category == null) {
      _snack('Please select a category');
      return;
    }
    if (_position == null) {
      _snack('Location not available. Tap the refresh icon.');
      return;
    }

    final svc = context.read<ComplaintService>();
    final userSvc = context.read<UserService>();
    final user = await userSvc.userStream.first;

    final id = await svc.submitComplaint(
      imageFile: _image!,
      category: _category!,
      lat: _position!.latitude,
      lng: _position!.longitude,
      ward: user?.ward ?? 'Ward 1',
      description: _descCtrl.text,
    );

    if (!mounted) return;
    if (id != null) {
      await userSvc.addPoints(10);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SuccessScreen(id: id)),
      );
    } else {
      _snack(svc.lastError ?? 'Submission failed. Please try again.');
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ComplaintService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Issue'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            const Text('📸 Photo (Required)',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showPicker,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _image != null
                        ? const Color(0xFF1B5E20)
                        : Colors.grey.shade300,
                    width: _image != null ? 2 : 1,
                  ),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.file(_image!, fit: BoxFit.cover))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              size: 44,
                              color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Tap to add photo',
                              style:
                                  TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Category
            const Text('📂 Category',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final sel = _category == cat['v'];
                return GestureDetector(
                  onTap: () => setState(() => _category = cat['v']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFF1B5E20)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel
                            ? const Color(0xFF1B5E20)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text('${cat['e']} ${cat['v']}',
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.black87,
                          fontWeight: sel
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Location
            const Text('📍 Location',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    _position != null
                        ? Icons.location_on
                        : Icons.location_off,
                    color: _position != null ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _gettingLoc
                        ? const Text('Getting location...',
                            style: TextStyle(color: Colors.grey))
                        : Text(
                            _position != null
                                ? '${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}'
                                : 'Location unavailable - tap refresh',
                            style: TextStyle(
                                color: _position != null
                                    ? Colors.black87
                                    : Colors.red,
                                fontSize: 13),
                          ),
                  ),
                  if (_gettingLoc)
                    const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: _getLocation),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Description
            const Text('📝 Description (Optional)',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration:
                  const InputDecoration(hintText: 'Describe the issue...'),
            ),
            const SizedBox(height: 12),

            // AI note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Text('🤖', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI will analyze your photo for waste type & recycling advice',
                      style:
                          TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: svc.isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6D00),
                    foregroundColor: Colors.white),
                child: svc.isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Submitting...'),
                        ],
                      )
                    : const Text('Submit Report (+10 pts)',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Photo',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PickOpt(Icons.camera_alt, 'Camera', () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                }),
                _PickOpt(Icons.photo_library, 'Gallery', () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PickOpt extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickOpt(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 32, color: const Color(0xFF1B5E20)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
