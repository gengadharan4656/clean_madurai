// lib/screens/report/report_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../services/user_service.dart';
import '../report/complaint_success_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  File? _imageFile;
  String? _category;
  final _descController = TextEditingController();
  Position? _position;
  bool _fetchingLocation = false;

  final List<Map<String, String>> _categories = [
    {'label': 'Garbage Overflow', 'value': 'Garbage overflow', 'emoji': '🗑️'},
    {'label': 'Open Dumping', 'value': 'Open dumping', 'emoji': '♻️'},
    {'label': 'Sewer Blockage', 'value': 'Sewer blockage', 'emoji': '🚰'},
    {'label': 'Public Toilet Issue', 'value': 'Public toilet issue', 'emoji': '🚽'},
    {'label': 'Littering', 'value': 'Littering', 'emoji': '🍃'},
    {'label': 'Other', 'value': 'Other', 'emoji': '📋'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      setState(() {
        _position = pos;
        _fetchingLocation = false;
      });
    } catch (e) {
      setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75, maxWidth: 1080);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _submitReport() async {
    if (_imageFile == null) {
      _showSnack('Please add a photo');
      return;
    }
    if (_category == null) {
      _showSnack('Please select a category');
      return;
    }
    if (_position == null) {
      _showSnack('Location not available. Please enable GPS.');
      return;
    }

    final complaintService = context.read<ComplaintService>();
    final userService = context.read<UserService>();
    final userSnap = await userService.userStream.first;
    final ward = userSnap?.ward ?? 'Ward 1';

    final complaintId = await complaintService.submitComplaint(
      imageFile: _imageFile!,
      category: _category!,
      lat: _position!.latitude,
      lng: _position!.longitude,
      locationName: 'Madurai (${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)})',
      description: _descController.text,
      ward: ward,
    );

    if (!mounted) return;

    if (complaintId != null) {
      // Award points
      await userService.addPoints(10);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ComplaintSuccessScreen(complaintId: complaintId),
        ),
      );
    } else {
      _showSnack('Submission failed. Please try again.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final complaintService = context.watch<ComplaintService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Report Cleanliness Issue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Section
            const Text('📸 Add Photo (Required)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showImagePicker(),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _imageFile != null ? AppTheme.primary : Colors.grey.shade300,
                    width: _imageFile != null ? 2 : 1,
                  ),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Tap to add photo', style: TextStyle(color: Colors.grey.shade500)),
                          const SizedBox(height: 4),
                          Text('Camera or Gallery', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Category
            const Text('📂 Issue Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final selected = _category == cat['value'];
                return GestureDetector(
                  onTap: () => setState(() => _category = cat['value']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppTheme.primary : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat['emoji']!),
                        const SizedBox(width: 6),
                        Text(
                          cat['label']!,
                          style: TextStyle(
                            color: selected ? Colors.white : AppTheme.textDark,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Location
            const Text('📍 Location', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    _position != null ? Icons.location_on : Icons.location_searching,
                    color: _position != null ? AppTheme.primary : Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _fetchingLocation
                        ? const Text('Getting location...')
                        : Text(
                            _position != null
                                ? 'GPS: ${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}'
                                : 'Location unavailable',
                            style: TextStyle(
                              color: _position != null ? AppTheme.textDark : Colors.red,
                            ),
                          ),
                  ),
                  if (_fetchingLocation)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _fetchLocation,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Description
            const Text('📝 Description (Optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe the issue...',
              ),
            ),
            const SizedBox(height: 12),

            // AI notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('🤖', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'AI will automatically analyze your photo and suggest recycling guidance',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMed),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: complaintService.isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                ),
                child: complaintService.isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Submitting & Analyzing...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send),
                          SizedBox(width: 8),
                          Text('Submit Report (+10 pts)'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PickerOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _PickerOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 32, color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
