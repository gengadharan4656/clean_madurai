import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/image_upload_service.dart';
import '../../services/ai_service.dart';
import '../../services/n8n_service.dart';
import '../../services/points_service.dart';
import '../../utils/app_theme.dart';

class CollectorScreen extends StatefulWidget {
  const CollectorScreen({super.key});

  @override
  State<CollectorScreen> createState() => _CollectorScreenState();
}

class _CollectorScreenState extends State<CollectorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Collector Portal'),
        backgroundColor: AppTheme.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: '📋 Tasks'),
            Tab(text: '📸 Before/After'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _TasksTab(),
          const _BeforeAfterTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TASKS TAB
// ─────────────────────────────────────────────────────────────
class _TasksTab extends StatelessWidget {
  const _TasksTab();

  final List<Map<String, dynamic>> _tasks = const [
    {
      'id': 'T001', 'location': 'Meenakshi Temple Rd', 'ward': '1',
      'severity': 'critical', 'time': '9:14 AM', 'status': 'pending',
      'description': 'Large garbage pile near temple entrance',
    },
    {
      'id': 'T002', 'location': 'KK Nagar Main Rd', 'ward': '5',
      'severity': 'high', 'time': '10:32 AM', 'status': 'in_progress',
      'description': 'Overflowing dustbin at junction',
    },
    {
      'id': 'T003', 'location': 'Anna Nagar Park', 'ward': '4',
      'severity': 'medium', 'time': '11:05 AM', 'status': 'pending',
      'description': 'Scattered plastic waste in park',
    },
    {
      'id': 'T004', 'location': 'Bypass Road', 'ward': '2',
      'severity': 'low', 'time': '8:45 AM', 'status': 'completed',
      'description': 'Small waste pile on roadside',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      itemBuilder: (ctx, i) => _buildTaskCard(context, _tasks[i]),
    );
  }

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> task) {
    final severityColors = {
      'critical': AppTheme.error,
      'high': AppTheme.accentOrange,
      'medium': AppTheme.warning,
      'low': AppTheme.success,
    };
    final statusColors = {
      'pending': AppTheme.warning,
      'in_progress': AppTheme.accentBlue,
      'completed': AppTheme.success,
    };
    final color = severityColors[task['severity']] ?? AppTheme.textSecondary;
    final statusColor = statusColors[task['status']] ?? AppTheme.textMuted;
    final isCompleted = task['status'] == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCompleted ? AppTheme.cardBorder : color.withOpacity(0.3),
        ),
        boxShadow: isCompleted
            ? null
            : [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (task['severity'] as String).toUpperCase(),
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (task['status'] as String).replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                Text(task['time'], style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task['location'],
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('Ward ${task['ward']} • ${task['description']}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.navigation_rounded, size: 16),
                      label: const Text('Navigate', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentBlue,
                        side: const BorderSide(color: AppTheme.accentBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/collector',
                            arguments: {'task': task});
                      },
                      icon: const Icon(Icons.camera_alt_rounded, size: 16),
                      label: const Text('Upload Before/After', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: AppTheme.bg,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BEFORE / AFTER COMPARISON TAB - FIXED
// ─────────────────────────────────────────────────────────────
class _BeforeAfterTab extends StatefulWidget {
  const _BeforeAfterTab();

  @override
  State<_BeforeAfterTab> createState() => _BeforeAfterTabState();
}

class _BeforeAfterTabState extends State<_BeforeAfterTab> {
  File? _beforeImage;
  File? _afterImage;
  bool _isAnalyzing = false;
  bool _isSubmitting = false;
  BeforeAfterComparison? _comparison;
  double _uploadProgress = 0;
  String _currentTaskId = 'T001';
  String _ward = '1';

  Future<void> _pickBeforeImage() async {
    final file = await ImageUploadService.pickImage(
      source: ImageSource.camera,
      crop: false, // Don't crop before — need full view
    );
    if (file != null) {
      setState(() {
        _beforeImage = file;
        _comparison = null;
      });
    }
  }

  Future<void> _pickAfterImage() async {
    if (_beforeImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take the BEFORE photo first')),
      );
      return;
    }
    final file = await ImageUploadService.pickImage(
      source: ImageSource.camera,
      crop: false,
    );
    if (file != null) {
      setState(() {
        _afterImage = file;
        _comparison = null;
      });
      // Auto analyze
      await _analyzeComparison();
    }
  }

  Future<void> _analyzeComparison() async {
    if (_beforeImage == null || _afterImage == null) return;
    setState(() => _isAnalyzing = true);
    final result = await AiService.compareBeforeAfter(
      beforeImage: _beforeImage!,
      afterImage: _afterImage!,
    );
    if (mounted) {
      setState(() {
        _comparison = result;
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _submitBeforeAfter() async {
    if (_beforeImage == null || _afterImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take both before and after photos')),
      );
      return;
    }
    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0;
    });

    try {
      // Upload before image
      final beforeUrl = await ImageUploadService.uploadImage(
        imageFile: _beforeImage!,
        folder: 'before_after/before',
        onProgress: (p) => setState(() => _uploadProgress = p * 0.5),
      );

      // Upload after image
      final afterUrl = await ImageUploadService.uploadImage(
        imageFile: _afterImage!,
        folder: 'before_after/after',
        onProgress: (p) => setState(() => _uploadProgress = 0.5 + p * 0.5),
      );

      if (beforeUrl == null || afterUrl == null) {
        throw Exception('Upload failed');
      }

      // Award points
      final points = await PointsService.awardPoints(
        activity: 'collector_task_complete',
        metadata: {
          'task_id': _currentTaskId,
          'improvement': _comparison?.improvementPercent ?? 0,
        },
      );

      if (_comparison?.isApproved == true) {
        await PointsService.awardPoints(activity: 'before_after_verified');
      }

      // Notify via n8n
      await N8nService.notifyPickupComplete(
        collectorId: 'collector_001',
        ward: _ward,
        beforeImageUrl: beforeUrl,
        afterImageUrl: afterUrl,
        pointsAwarded: points + (_comparison?.pointsEarned ?? 0),
        residentPhone: '',
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showSuccessDialog() {
    final pts = (_comparison?.pointsEarned ?? 0) + 60;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Task Completed!',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (_comparison != null) ...[
              Text(
                'Improvement: ${_comparison!.improvementPercent}%',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Verified: ${_comparison!.verificationStatus.toUpperCase()}',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('+$pts pts earned',
                  style: const TextStyle(color: AppTheme.accent, fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _beforeImage = null;
                _afterImage = null;
                _comparison = null;
              });
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Info Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI will automatically compare before/after photos and verify cleanup quality',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Before / After Image Pickers
          Row(
            children: [
              Expanded(child: _buildImagePicker('BEFORE', _beforeImage, _pickBeforeImage, AppTheme.warning)),
              const SizedBox(width: 14),
              Expanded(child: _buildImagePicker('AFTER', _afterImage, _pickAfterImage, AppTheme.success)),
            ],
          ),
          const SizedBox(height: 16),

          // AI Comparison Result
          if (_isAnalyzing)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentBlue),
                  ),
                  SizedBox(width: 12),
                  Text('AI analyzing before/after comparison...',
                      style: TextStyle(color: AppTheme.accentBlue)),
                ],
              ),
            )
          else if (_comparison != null)
            _buildComparisonResult(_comparison!),

          const SizedBox(height: 20),

          // Submit Button
          if (_beforeImage != null && _afterImage != null)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: _isSubmitting
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              value: _uploadProgress,
                              color: AppTheme.primary,
                              strokeWidth: 2,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Uploading ${(_uploadProgress * 100).round()}%',
                              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _submitBeforeAfter,
                      icon: const Icon(Icons.upload_rounded),
                      label: const Text('Submit & Complete Task'),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(String label, File? image, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: image != null ? color.withOpacity(0.5) : AppTheme.cardBorder,
            width: image != null ? 2 : 1,
          ),
        ),
        child: image != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(image, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(label,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppTheme.bg.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.refresh_rounded, size: 14, color: AppTheme.textPrimary),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      label == 'BEFORE' ? Icons.camera_rear_rounded : Icons.camera_front_rounded,
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(label,
                      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    label == 'BEFORE' ? 'Before cleanup' : 'After cleanup',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildComparisonResult(BeforeAfterComparison comp) {
    final statusColor = comp.verificationStatus == 'excellent'
        ? AppTheme.success
        : comp.verificationStatus == 'good'
            ? AppTheme.primary
            : comp.verificationStatus == 'acceptable'
                ? AppTheme.warning
                : AppTheme.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentBlue, size: 18),
              const SizedBox(width: 8),
              const Text('AI Verification', style: TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  comp.verificationStatus.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildCompScore('Before', comp.beforeScore, AppTheme.warning),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded, color: AppTheme.textMuted),
              ),
              Expanded(
                child: _buildCompScore('After', comp.afterScore, AppTheme.success),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Improvement', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  Text('${comp.improvementPercent}%',
                      style: TextStyle(color: statusColor, fontSize: 22, fontWeight: FontWeight.w800)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: AppTheme.accent, size: 18),
                    const SizedBox(width: 6),
                    Text('+${comp.pointsEarned} pts',
                        style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
          if (!comp.isApproved) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_rounded, color: AppTheme.error, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Improvement insufficient. Please clean more thoroughly and retake the after photo.',
                      style: TextStyle(color: AppTheme.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompScore(String label, int score, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 56, height: 56,
              child: CircularProgressIndicator(
                value: score / 100,
                backgroundColor: AppTheme.cardBorder,
                color: color,
                strokeWidth: 4,
              ),
            ),
            Text('$score', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
      ],
    );
  }
}
