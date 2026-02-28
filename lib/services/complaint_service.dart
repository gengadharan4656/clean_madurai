import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';

class ComplaintModel {
  final String id;
  final String userId;
  final String category;
  final String description;
  final String imageBeforeUrl;
  final String? imageAfterUrl;
  final double lat;
  final double lng;
  final String ward;
  final String status;
  final String priority;
  final String? aiWasteType;
  final String? recyclingMethod;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  // Feature 1: resolution metadata
  final double? resolutionTimeHours;
  final String? resolutionBadge;

  ComplaintModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.description,
    required this.imageBeforeUrl,
    this.imageAfterUrl,
    required this.lat,
    required this.lng,
    required this.ward,
    required this.status,
    required this.priority,
    this.aiWasteType,
    this.recyclingMethod,
    this.createdAt,
    this.resolvedAt,
    this.resolutionTimeHours,
    this.resolutionBadge,
  });

  factory ComplaintModel.fromMap(String id, Map<String, dynamic> d) {
    final loc = d['location'] as Map<String, dynamic>? ?? {};
    return ComplaintModel(
      id: id,
      userId: d['userId'] ?? '',
      category: d['category'] ?? '',
      description: d['description'] ?? '',
      imageBeforeUrl: d['imageBeforeUrl'] ?? '',
      imageAfterUrl: d['imageAfterUrl'],
      lat: (loc['lat'] as num?)?.toDouble() ?? 9.9252,
      lng: (loc['lng'] as num?)?.toDouble() ?? 78.1198,
      ward: d['ward'] ?? 'Ward 1',
      status: d['status'] ?? 'submitted',
      priority: d['priority'] ?? 'low',
      aiWasteType: d['aiWasteType'],
      recyclingMethod: d['recyclingMethod'],
      createdAt: d['createdAt'] != null
          ? (d['createdAt'] as dynamic).toDate()
          : null,
      resolvedAt: d['resolvedAt'] != null
          ? (d['resolvedAt'] as dynamic).toDate()
          : null,
      resolutionTimeHours: (d['resolutionTimeHours'] as num?)?.toDouble(),
      resolutionBadge: d['resolutionBadge'] as String?,
    );
  }

  String get statusEmoji {
    switch (status) {
      case 'submitted': return '📤 Submitted';
      case 'assigned': return '👷 Assigned';
      case 'in_progress': return '🔧 In Progress';
      case 'resolved': return '✅ Resolved';
      default: return '❓ Unknown';
    }
  }
}

class ComplaintService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();

  static const String _visionApiKey =
      String.fromEnvironment('VISION_API_KEY', defaultValue: '');

  String? _lastError;
  String? get lastError => _lastError;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  Future<String?> submitComplaint({
    required File imageFile,
    required String category,
    required double lat,
    required double lng,
    required String ward,
    String description = '',
  }) async {
    _isSubmitting = true;
    _lastError = null;
    notifyListeners();

    try {
      final uid = _auth.currentUser?.uid ?? '';
      final complaintId = _uuid.v4().substring(0, 8).toUpperCase();

      final imageUrl = await _uploadImage(imageFile, complaintId);
      final aiResult = await _analyzeWaste(imageFile);

      await _db.collection('complaints').doc(complaintId).set({
        'id': complaintId,
        'userId': uid,
        'category': category,
        'description': description,
        'imageBeforeUrl': imageUrl,
        'imageAfterUrl': null,
        'location': {'lat': lat, 'lng': lng},
        'ward': ward,
        'status': 'submitted',
        'priority': _priority(category),
        'aiWasteType': aiResult['wasteType'],
        'recyclingMethod': aiResult['recyclingMethod'],
        'createdAt': FieldValue.serverTimestamp(),
        'resolvedAt': null,
        // Feature 1 fields initialised as null
        'resolutionTimeHours': null,
        'resolutionBadge': null,
      });

      if (uid.isNotEmpty) {
        await _db.collection('users').doc(uid).set({
          'totalComplaints': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }

      _isSubmitting = false;
      notifyListeners();
      return complaintId;
    } on FirebaseException catch (e) {
      _lastError = e.message ?? 'Firebase error while submitting complaint.';
      debugPrint('Submit Firebase error: ${e.code} ${e.message}');
      _isSubmitting = false;
      notifyListeners();
      return null;
    } on PlatformException catch (e) {
      _lastError = e.message ?? 'Device error while uploading image.';
      debugPrint('Submit platform error: ${e.code} ${e.message}');
      _isSubmitting = false;
      notifyListeners();
      return null;
    } catch (e) {
      _lastError = 'Unexpected error while submitting complaint.';
      debugPrint('Submit error: $e');
      _isSubmitting = false;
      notifyListeners();
      return null;
    }
  }

  Future<String> _uploadImage(File imageFile, String id) async {
    final uid = _auth.currentUser?.uid ?? 'anonymous';
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('complaints/$uid/$id-$ts-before.jpg');
    final task = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    try {
      return await task.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
      await Future.delayed(const Duration(milliseconds: 500));
      return await task.ref.getDownloadURL();
    }
  }

  Future<Map<String, String>> _analyzeWaste(File imageFile) async {
    if (_visionApiKey.isEmpty) {
      return {
        'wasteType': '🗑️ Mixed Waste',
        'recyclingMethod':
            'AI temporarily unavailable. Please segregate into wet and dry waste.',
      };
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http
          .post(
            Uri.parse(
                'https://vision.googleapis.com/v1/images:annotate?key=$_visionApiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'requests': [
                {
                  'image': {'content': base64Image},
                  'features': [
                    {'type': 'LABEL_DETECTION', 'maxResults': 10}
                  ]
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final labels = data['responses']?[0]?['labelAnnotations'] as List?;
        if (labels != null) return _classify(labels);
      } else {
        debugPrint(
            'Vision API non-200: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('AI error (non-critical): $e');
    }

    return {
      'wasteType': '🗑️ Mixed Waste',
      'recyclingMethod': 'Please segregate at collection point.',
    };
  }

  Map<String, String> _classify(List labels) {
    final strs =
        labels.map((l) => (l['description'] as String).toLowerCase()).toList();

    if (strs.any((l) =>
        ['plastic', 'bottle', 'polyethylene', 'bag'].contains(l))) {
      return {
        'wasteType': '♻️ Plastic',
        'recyclingMethod': 'Place in Blue bin. Rinse before disposal.',
      };
    } else if (strs.any((l) =>
        ['food', 'vegetable', 'fruit', 'organic', 'leaf'].contains(l))) {
      return {
        'wasteType': '🌿 Organic / Food Waste',
        'recyclingMethod': 'Place in Green bin. Can be composted.',
      };
    } else if (strs.any((l) => ['glass', 'jar'].contains(l))) {
      return {
        'wasteType': '🫙 Glass',
        'recyclingMethod': 'Wrap in newspaper, place in Dry Waste bin.',
      };
    } else if (strs.any(
        (l) => ['metal', 'iron', 'aluminum', 'can', 'steel'].contains(l))) {
      return {
        'wasteType': '🔩 Metal',
        'recyclingMethod': 'Place in Dry Waste bin. Fully recyclable.',
      };
    } else if (strs.any((l) =>
        ['electronics', 'computer', 'phone', 'battery'].contains(l))) {
      return {
        'wasteType': '⚡ E-Waste',
        'recyclingMethod':
            '⚠️ Take to nearest e-waste collection center. DO NOT mix with regular waste.',
      };
    }

    return {
      'wasteType': '🗑️ Mixed Waste',
      'recyclingMethod': 'Segregate into wet and dry before disposal.',
    };
  }

  String _priority(String category) {
    switch (category) {
      case 'Sewer Blockage': return 'critical';
      case 'Garbage Overflow': return 'high';
      case 'Open Dumping': return 'high';
      case 'Public Toilet Issue': return 'medium';
      default: return 'low';
    }
  }

  Stream<List<ComplaintModel>> get myComplaints {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return const Stream.empty();
    return _db
        .collection('complaints')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ComplaintModel.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<ComplaintModel>> publicFeed({String? ward}) {
    Query<Map<String, dynamic>> query = _db
        .collection('complaints')
        .where('status', isEqualTo: 'resolved')
        .orderBy('resolvedAt', descending: true);

    if (ward != null && ward.isNotEmpty) {
      query = query.where('ward', isEqualTo: ward);
    }

    return query
        .limit(20)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ComplaintModel.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<ComplaintModel>> collectorWardQueue(String ward) {
    return _db
        .collection('complaints')
        .where('ward', isEqualTo: ward)
        .where('status', whereIn: ['submitted', 'assigned', 'in_progress'])
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ComplaintModel.fromMap(d.id, d.data()))
            .toList());
  }

  Future<bool> collectorUpdateComplaint({
    required String complaintId,
    required String status,
    File? afterImage,
  }) async {
    try {
      final update = <String, dynamic>{'status': status};

      if (status == 'resolved') {
        final now = DateTime.now();
        update['resolvedAt'] = FieldValue.serverTimestamp();

        // Feature 1: compute resolutionTimeHours and badge
        final doc = await _db.collection('complaints').doc(complaintId).get();
        final createdAt =
            (doc.data()?['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null) {
          final hours = now.difference(createdAt).inMinutes / 60.0;
          update['resolutionTimeHours'] = double.parse(hours.toStringAsFixed(2));
          if (hours < 6) {
            update['resolutionBadge'] = 'Fast';
          } else if (hours <= 24) {
            update['resolutionBadge'] = 'Normal';
          } else {
            update['resolutionBadge'] = 'Delayed';
          }
        }
      }

      if (afterImage != null) {
        final url = await _uploadAfterImage(afterImage, complaintId);
        update['imageAfterUrl'] = url;
      }

      await _db.collection('complaints').doc(complaintId).set(
        update,
        SetOptions(merge: true),
      );

      if (status == 'resolved') {
        final collectorId = _auth.currentUser?.uid;
        if (collectorId != null && collectorId.isNotEmpty) {
          await _db.collection('users').doc(collectorId).set({
            'cleanlinessScore': FieldValue.increment(20),
            'resolvedComplaints': FieldValue.increment(1),
          }, SetOptions(merge: true));
        }
      }

      return true;
    } on FirebaseException catch (e) {
      _lastError = e.message ?? 'Failed to update complaint.';
      notifyListeners();
      return false;
    }
  }

  Future<String> _uploadAfterImage(File imageFile, String id) async {
    final uid = _auth.currentUser?.uid ?? 'anonymous';
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('complaints/$uid/$id-$ts-after.jpg');
    final task = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }
}
