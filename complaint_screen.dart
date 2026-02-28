import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../services/image_upload_service.dart';
import '../../services/location_service.dart';
import '../../services/ai_service.dart';
import '../../services/n8n_service.dart';
import '../../services/points_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_card.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();

  File? _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0;
  bool _isSubmitting = false;
  bool _locationFetching = false;
  double? _lat, _lng;
  String _severity = 'medium';
  String _ward = '1';
  GarbageAnalysis? _aiAnalysis;
  bool _isAnalyzing = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  final List<String> _wards = List.generate(50, (i) => '${i + 1}');
  final List<Map<String, dynamic>> _severityOptions = [
    {'value': 'low', 'label': 'Low', 'color': AppTheme.success, 'icon': Icons.info_outline},
    {'value': 'medium', 'label': 'Medium', 'color': AppTheme.warning, 'icon': Icons.warning_amber_rounded},
    {'value': 'high', 'label': 'High', 'color': AppTheme.accentOrange, 'icon': Icons.error_outline},
    {'value': 'critical', 'label': 'Critical', 'color': AppTheme.error, 'icon': Icons.dangerous_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    _fetchLocation();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _locationFetching = true);
    final position = await LocationService.getCurrentPosition(context: context);
    if (position != null && mounted) {
      _lat = position.latitude;
      _lng = position.longitude;
      final address = await LocationService.getAddressFromCoords(_lat!, _lng!);
      setState(() {
        _locationController.text = address;
        _locationFetching = false;
      });
    } else {
      setState(() => _locationFetching = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // PICK IMAGE - FIXED
  // ─────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final source = await ImageUploadService.showSourceDialog(context);
    if (source == null) return;

    try {
      final file = await ImageUploadService.pickImage(
        source: source,
        imageQuality: 85,
        crop: true,
      );

      if (file != null && mounted) {
        setState(() {
          _selectedImage = file;
          _aiAnalysis = null;
        });
        // Auto-analyze with AI
        _analyzeImage(file);
      }
    } catch (e) {
      _showError('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _analyzeImage(File image) async {
    setState(() => _isAnalyzing = true);
    try {
      final analysis = await AiService.analyzeGarbageImage(image);
      if (mounted) {
        setState(() {
          _aiAnalysis = analysis;
          _isAnalyzing = false;
          // Auto-set severity from AI
          _severity = analysis.severity;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SUBMIT COMPLAINT - FIXED upload + n8n trigger
  // ─────────────────────────────────────────────────────────────
  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      _showError('Please upload an image of the garbage');
      return;
    }
    if (_lat == null || _lng == null) {
      _showError('Location is required. Please enable location.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload image with progress
      setState(() => _isUploading = true);
      final String? imageUrl = await ImageUploadService.uploadImage(
        imageFile: _selectedImage!,
        folder: 'complaints',
        onProgress: (progress) {
          if (mounted) setState(() => _uploadProgress = progress);
        },
      );

      if (imageUrl == null) {
        throw Exception('Image upload failed. Please try again.');
      }

      setState(() => _isUploading = false);

      // 2. Save to Firestore
      final String complaintId = const Uuid().v4();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .set({
        'id': complaintId,
        'user_id': uid,
        'description': _descController.text.trim(),
        'location': _locationController.text.trim(),
        'latitude': _lat,
        'longitude': _lng,
        'ward': _ward,
        'image_url': imageUrl,
        'severity': _severity,
        'status': 'pending',
        'ai_analysis': _aiAnalysis != null ? {
          'is_garbage': _aiAnalysis!.isGarbage,
          'severity': _aiAnalysis!.severity,
          'category': _aiAnalysis!.category,
          'confidence': _aiAnalysis!.confidence,
          'description': _aiAnalysis!.description,
        } : null,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 3. Award points
      await PointsService.awardPoints(
        activity: 'complaint_submitted',
        referenceId: complaintId,
        metadata: {'severity': _severity},
      );

      // 4. Trigger n8n to notify collector
      await N8nService.triggerGarbageCollector(
        complaintId: complaintId,
        location: _locationController.text.trim(),
        ward: _ward,
        latitude: _lat!,
        longitude: _lng!,
        imageUrl: imageUrl,
        severity: _severity,
        reportedBy: uid,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccess(complaintId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isUploading = false;
        });
        _showError('Submission failed: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: AppTheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: AppTheme.card,
      ),
    );
  }

  void _showSuccess(String complaintId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Complaint Submitted!',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('ID: ${complaintId.substring(0, 8).toUpperCase()}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            const Text(
              'Garbage collector has been notified via WhatsApp. You earned 10 points!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.star_rounded, color: AppTheme.accent, size: 16),
                      SizedBox(width: 4),
                      Text('+10 pts', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Report Garbage'),
        backgroundColor: AppTheme.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.campaign_rounded, color: AppTheme.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Report garbage to alert the collector instantly via WhatsApp & SMS',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Image Upload - FIXED
                _buildImageSection(),
                const SizedBox(height: 20),

                // AI Analysis Result
                if (_aiAnalysis != null) _buildAiAnalysisCard(),

                // Severity
                _buildSectionLabel('Severity Level'),
                const SizedBox(height: 10),
                _buildSeveritySelector(),
                const SizedBox(height: 20),

                // Location
                _buildSectionLabel('Location'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _locationController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter location or use GPS',
                    prefixIcon: const Icon(Icons.location_on_rounded, color: AppTheme.primary),
                    suffixIcon: _locationFetching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.primary),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.my_location_rounded, color: AppTheme.primary),
                            onPressed: _fetchLocation,
                          ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Location is required' : null,
                ),
                const SizedBox(height: 20),

                // Ward
                _buildSectionLabel('Ward Number'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _ward,
                  dropdownColor: AppTheme.card,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_city_rounded, color: AppTheme.primary),
                    hintText: 'Select ward',
                  ),
                  items: _wards
                      .map((w) => DropdownMenuItem(
                            value: w,
                            child: Text('Ward $w'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _ward = v!),
                ),
                const SizedBox(height: 20),

                // Description
                _buildSectionLabel('Description'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Describe the garbage issue...',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.description_rounded, color: AppTheme.primary),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().length < 10
                          ? 'Please provide at least 10 characters'
                          : null,
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: _isSubmitting
                      ? _buildProgressButton()
                      : ElevatedButton.icon(
                          onPressed: _submitComplaint,
                          icon: const Icon(Icons.send_rounded),
                          label: const Text('Submit Complaint'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.bg,
                          ),
                        ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Photo Evidence *'),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _isUploading ? null : _pickImage,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedImage != null
                    ? AppTheme.primary.withOpacity(0.5)
                    : AppTheme.cardBorder,
                width: 1.5,
              ),
            ),
            child: _selectedImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          _selectedImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (_isUploading)
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.bg.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  value: _uploadProgress,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(_uploadProgress * 100).round()}%',
                                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_isAnalyzing)
                        Positioned(
                          bottom: 12, right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.bg.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 12, height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.accentBlue),
                                ),
                                SizedBox(width: 6),
                                Text('AI analyzing...', style: TextStyle(color: AppTheme.accentBlue, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      if (!_isUploading)
                        Positioned(
                          top: 10, right: 10,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.bg.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.edit_rounded, color: AppTheme.textPrimary, size: 16),
                            ),
                          ),
                        ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_a_photo_rounded,
                          color: AppTheme.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tap to add photo',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Camera or Gallery • AI analyzes automatically',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiAnalysisCard() {
    if (_aiAnalysis == null) return const SizedBox.shrink();
    final severityColor = _severity == 'critical'
        ? AppTheme.error
        : _severity == 'high'
            ? AppTheme.accentOrange
            : _severity == 'medium'
                ? AppTheme.warning
                : AppTheme.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentBlue, size: 18),
              const SizedBox(width: 8),
              const Text('AI Analysis', style: TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _aiAnalysis!.severity.toUpperCase(),
                  style: TextStyle(color: severityColor, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_aiAnalysis!.description,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          if (_aiAnalysis!.suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...(_aiAnalysis!.suggestions.map((s) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(children: [
                const Icon(Icons.arrow_right_rounded, color: AppTheme.primary, size: 18),
                Expanded(child: Text(s, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
              ]),
            ))),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: AppTheme.accent, size: 16),
              const SizedBox(width: 4),
              Text(
                'Estimated reward: +${_aiAnalysis!.estimatedPoints} pts',
                style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeveritySelector() {
    return Row(
      children: _severityOptions.map((opt) {
        final isSelected = _severity == opt['value'];
        final color = opt['color'] as Color;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _severity = opt['value']),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : AppTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : AppTheme.cardBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(opt['icon'] as IconData, color: isSelected ? color : AppTheme.textMuted, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    opt['label'],
                    style: TextStyle(
                      color: isSelected ? color : AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Text(
              _isUploading
                  ? 'Uploading ${(_uploadProgress * 100).round()}%...'
                  : 'Submitting...',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
