// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String ward;
  final String role;
  final int cleanlinessScore;
  final int totalComplaints;
  final int resolvedComplaints;
  final List<String> badges;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.ward,
    required this.role,
    required this.cleanlinessScore,
    required this.totalComplaints,
    required this.resolvedComplaints,
    required this.badges,
    this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      email: d['email'] ?? '',
      ward: d['ward'] ?? '',
      role: d['role'] ?? 'citizen',
      cleanlinessScore: (d['cleanlinessScore'] as int?) ?? 0,
      totalComplaints: (d['totalComplaints'] as int?) ?? 0,
      resolvedComplaints: (d['resolvedComplaints'] as int?) ?? 0,
      badges: List<String>.from(d['badges'] ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  String get badgeLabel {
    if (badges.contains('gold')) return '🥇 Gold';
    if (badges.contains('silver')) return '🥈 Silver';
    if (badges.contains('bronze')) return '🥉 Bronze';
    return '🌱 Beginner';
  }
}
