// lib/models/complaint_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String userId;
  final String category;
  final String description;
  final String imageBeforeUrl;
  final String? imageAfterUrl;
  final double lat;
  final double lng;
  final String locationName;
  final String ward;
  final String status;
  final String priority;
  final String? aiWasteType;
  final String? recyclingMethod;
  final String? aiDescription;
  final String? assignedTo;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  ComplaintModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.description,
    required this.imageBeforeUrl,
    this.imageAfterUrl,
    required this.lat,
    required this.lng,
    required this.locationName,
    required this.ward,
    required this.status,
    required this.priority,
    this.aiWasteType,
    this.recyclingMethod,
    this.aiDescription,
    this.assignedTo,
    this.createdAt,
    this.resolvedAt,
  });

  factory ComplaintModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final location = d['location'] as Map<String, dynamic>? ?? {};
    return ComplaintModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      category: d['category'] ?? '',
      description: d['description'] ?? '',
      imageBeforeUrl: d['imageBeforeUrl'] ?? '',
      imageAfterUrl: d['imageAfterUrl'],
      lat: (location['lat'] as num?)?.toDouble() ?? 9.9252,
      lng: (location['lng'] as num?)?.toDouble() ?? 78.1198,
      locationName: (location['name'] as String?) ?? 'Madurai',
      ward: d['ward'] ?? '',
      status: d['status'] ?? 'submitted',
      priority: d['priority'] ?? 'low',
      aiWasteType: d['aiWasteType'],
      recyclingMethod: d['recyclingMethod'],
      aiDescription: d['aiDescription'],
      assignedTo: d['assignedTo'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      resolvedAt: (d['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get isResolved => status == 'resolved';

  String get statusEmoji {
    switch (status) {
      case 'submitted': return '📤';
      case 'assigned': return '👷';
      case 'in_progress': return '🔧';
      case 'resolved': return '✅';
      default: return '❓';
    }
  }

  String get priorityColor {
    switch (priority) {
      case 'critical': return '#E53935';
      case 'high': return '#FB8C00';
      case 'medium': return '#F9A825';
      default: return '#43A047';
    }
  }
}
