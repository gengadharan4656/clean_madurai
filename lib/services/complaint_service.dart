// lib/services/complaint_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/complaint_model.dart';

class ComplaintService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();

  // ⚠️ REPLACE with your n8n webhook URL
  static const String _n8nWebhookUrl = 'https://YOUR_N8N_INSTANCE/webhook/complaint-intake';
  // ⚠️ REPLACE with your Google Cloud Vision API key or Vertex AI endpoint
  static const String _visionApiKey = 'YOUR_GOOGLE_VISION_API_KEY';

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  // ─── SUBMIT COMPLAINT ────────────────────────────────────────

  Future<String?> submitComplaint({
    required File imageFile,
    required String category,
    required double lat,
    required double lng,
    required String locationName,
    String? description,
    required String ward,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final uid = _auth.currentUser?.uid ?? '';
      final complaintId = _uuid.v4().substring(0, 8).toUpperCase();

      // 1. Upload image to Firebase Storage
      final imageUrl = await _uploadImage(imageFile, complaintId);

      // 2. AI waste analysis
      final aiResult = await _analyzeWaste(imageFile);

      // 3. Save to Firestore
      final data = {
        'id': complaintId,
        'userId': uid,
        'category': category,
        'description': description ?? '',
        'imageBeforeUrl': imageUrl,
        'imageAfterUrl': null,
        'location': {'lat': lat, 'lng': lng, 'name': locationName},
        'ward': ward,
        'status': 'submitted',
        'priority': _calculatePriority(category),
        'aiWasteType': aiResult['wasteType'],
        'recyclingMethod': aiResult['recyclingMethod'],
        'aiDescription': aiResult['description'],
        'createdAt': FieldValue.serverTimestamp(),
        'resolvedAt': null,
        'assignedTo': null,
      };

      await _db.collection('complaints').doc(complaintId).set(data);

      // 4. Log event
      await _db.collection('logs').add({
        'complaintId': complaintId,
        'action': 'complaint_submitted',
        'performedBy': uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 5. Trigger n8n automation (non-blocking)
      _triggerN8nWebhook(complaintId, data);

      _isSubmitting = false;
      notifyListeners();
      return complaintId;
    } catch (e) {
      debugPrint('Submit error: $e');
      _isSubmitting = false;
      notifyListeners();
      return null;
    }
  }

  // ─── IMAGE UPLOAD ────────────────────────────────────────────

  Future<String> _uploadImage(File imageFile, String complaintId) async {
    final ref = _storage.ref('complaints/$complaintId/before.jpg');
    final task = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }

  // ─── AI WASTE ANALYSIS ───────────────────────────────────────

  Future<Map<String, String>> _analyzeWaste(File imageFile) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Google Cloud Vision API call
      final response = await http.post(
        Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$_visionApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requests': [
            {
              'image': {'content': base64Image},
              'features': [
                {'type': 'LABEL_DETECTION', 'maxResults': 10},
                {'type': 'OBJECT_LOCALIZATION', 'maxResults': 10},
              ],
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final labels = data['responses'][0]['labelAnnotations'] as List?;
        return _classifyWasteFromLabels(labels);
      }
    } catch (e) {
      debugPrint('AI analysis error: $e');
    }

    // Fallback if API fails
    return {
      'wasteType': 'Mixed Waste',
      'recyclingMethod': 'Please segregate at collection point',
      'description': 'Unable to analyze automatically. A worker will assess on-site.',
    };
  }

  Map<String, String> _classifyWasteFromLabels(List? labels) {
    if (labels == null || labels.isEmpty) {
      return {
        'wasteType': 'General Waste',
        'recyclingMethod': 'Dispose at nearest collection bin',
        'description': 'Mixed waste detected.',
      };
    }

    final labelStrings = labels
        .map((l) => (l['description'] as String).toLowerCase())
        .toList();

    // Simple rule-based classification
    if (labelStrings.any((l) => ['plastic', 'bottle', 'polyethylene', 'polypropylene'].contains(l))) {
      return {
        'wasteType': 'Plastic',
        'recyclingMethod': 'Place in Blue (Dry Waste) bin. Rinse bottles before disposal.',
        'description': 'Plastic waste detected. Plastic can be recycled — reduces pollution significantly.',
      };
    } else if (labelStrings.any((l) => ['food', 'organic', 'vegetable', 'fruit', 'leaf', 'plant'].contains(l))) {
      return {
        'wasteType': 'Organic / Food Waste',
        'recyclingMethod': 'Place in Green (Wet Waste) bin. Can be composted.',
        'description': 'Organic waste detected. Composting this waste creates valuable fertilizer.',
      };
    } else if (labelStrings.any((l) => ['glass', 'bottle', 'jar'].contains(l))) {
      return {
        'wasteType': 'Glass',
        'recyclingMethod': 'Wrap in newspaper and place in Dry Waste bin. Do NOT break.',
        'description': 'Glass waste detected. Recyclable — handle carefully to avoid injury.',
      };
    } else if (labelStrings.any((l) => ['metal', 'iron', 'steel', 'aluminum', 'can'].contains(l))) {
      return {
        'wasteType': 'Metal',
        'recyclingMethod': 'Place in Dry Waste bin. Metal is fully recyclable.',
        'description': 'Metal waste detected. Highly recyclable — saves significant energy vs new production.',
      };
    } else if (labelStrings.any((l) => ['electronics', 'computer', 'phone', 'battery', 'wire'].contains(l))) {
      return {
        'wasteType': 'E-Waste',
        'recyclingMethod': '⚠️ Do NOT mix with regular waste. Take to nearest e-waste collection center.',
        'description': 'Electronic waste detected. Contains hazardous materials — requires special disposal.',
      };
    } else {
      return {
        'wasteType': 'General Waste',
        'recyclingMethod': 'Segregate into wet and dry components before disposal.',
        'description': 'Mixed waste detected. Proper segregation helps maximize recycling.',
      };
    }
  }

  // ─── N8N WEBHOOK TRIGGER ─────────────────────────────────────

  Future<void> _triggerN8nWebhook(String complaintId, Map<String, dynamic> data) async {
    try {
      await http.post(
        Uri.parse(_n8nWebhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'complaintId': complaintId,
          'category': data['category'],
          'ward': data['ward'],
          'priority': data['priority'],
          'aiWasteType': data['aiWasteType'],
          'location': data['location'],
          'userId': data['userId'],
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('n8n webhook failed (non-critical): $e');
    }
  }

  // ─── QUERIES ────────────────────────────────────────────────

  /// All complaints for current user (real-time)
  Stream<List<ComplaintModel>> get myComplaints {
    final uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection('complaints')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ComplaintModel.fromFirestore(d)).toList());
  }

  /// Public feed — recently resolved complaints
  Stream<List<ComplaintModel>> get publicFeed {
    return _db
        .collection('complaints')
        .where('status', isEqualTo: 'resolved')
        .orderBy('resolvedAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map((d) => ComplaintModel.fromFirestore(d)).toList());
  }

  /// All complaints (admin)
  Stream<List<ComplaintModel>> getAllComplaints({String? ward, String? status}) {
    Query query = _db.collection('complaints').orderBy('createdAt', descending: true);
    if (ward != null) query = query.where('ward', isEqualTo: ward);
    if (status != null) query = query.where('status', isEqualTo: status);
    return query.snapshots().map((s) => s.docs.map((d) => ComplaintModel.fromFirestore(d)).toList());
  }

  // ─── ADMIN ACTIONS ───────────────────────────────────────────

  Future<void> updateStatus({
    required String complaintId,
    required String status,
    String? assignedTo,
    File? resolutionImage,
  }) async {
    final uid = _auth.currentUser?.uid ?? '';
    final updates = <String, dynamic>{'status': status};

    if (assignedTo != null) updates['assignedTo'] = assignedTo;
    if (status == 'resolved') updates['resolvedAt'] = FieldValue.serverTimestamp();

    if (resolutionImage != null) {
      final ref = _storage.ref('complaints/$complaintId/after.jpg');
      final task = await ref.putFile(resolutionImage);
      updates['imageAfterUrl'] = await task.ref.getDownloadURL();
    }

    await _db.collection('complaints').doc(complaintId).update(updates);
    await _db.collection('logs').add({
      'complaintId': complaintId,
      'action': 'status_updated_to_$status',
      'performedBy': uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Award points to citizen if resolved
    if (status == 'resolved') {
      final complaint = await _db.collection('complaints').doc(complaintId).get();
      final citizenId = complaint.data()?['userId'];
      if (citizenId != null) {
        await _db.collection('users').doc(citizenId).update({
          'cleanlinessScore': FieldValue.increment(10),
          'resolvedComplaints': FieldValue.increment(1),
        });
      }
    }
  }

  // ─── HELPERS ────────────────────────────────────────────────

  String _calculatePriority(String category) {
    switch (category) {
      case 'Garbage overflow': return 'high';
      case 'Open dumping': return 'high';
      case 'Sewer blockage': return 'critical';
      case 'Public toilet issue': return 'medium';
      default: return 'low';
    }
  }
}
