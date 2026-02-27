import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> d) {
    return UserModel(
      id: id,
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      email: d['email'] ?? '',
      ward: d['ward'] ?? 'Ward 1',
      role: d['role'] ?? 'citizen',
      cleanlinessScore: (d['cleanlinessScore'] as int?) ?? 0,
      totalComplaints: (d['totalComplaints'] as int?) ?? 0,
      resolvedComplaints: (d['resolvedComplaints'] as int?) ?? 0,
      badges: List<String>.from(d['badges'] ?? []),
    );
  }

  String get badgeLabel {
    if (badges.contains('gold')) return '🥇 Gold';
    if (badges.contains('silver')) return '🥈 Silver';
    if (badges.contains('bronze')) return '🥉 Bronze';
    return '🌱 Beginner';
  }
}

class UserService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser?.uid ?? '';

  Stream<UserModel?> get userStream {
    if (uid.isEmpty) return const Stream.empty();
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    });
  }

  Future<void> addPoints(int points) async {
    if (uid.isEmpty) return;
    final docRef = _db.collection('users').doc(uid);
    await docRef.update({'cleanlinessScore': FieldValue.increment(points)});

    final doc = await docRef.get();
    final score = (doc.data()?['cleanlinessScore'] as int?) ?? 0;
    final badges = List<String>.from(doc.data()?['badges'] ?? []);

    if (score >= 200 && !badges.contains('gold')) {
      badges.add('gold');
      await docRef.update({'badges': badges});
    } else if (score >= 100 && !badges.contains('silver')) {
      badges.add('silver');
      await docRef.update({'badges': badges});
    } else if (score >= 30 && !badges.contains('bronze')) {
      badges.add('bronze');
      await docRef.update({'badges': badges});
    }
  }

  Future<List<UserModel>> getLeaderboard(String ward) async {
    try {
      final q = await _db
          .collection('users')
          .where('ward', isEqualTo: ward)
          .orderBy('cleanlinessScore', descending: true)
          .limit(10)
          .get();
      return q.docs
          .map((d) => UserModel.fromMap(d.id, d.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
