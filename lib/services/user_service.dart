// lib/services/user_service.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _currentUserData;
  UserModel? get currentUserData => _currentUserData;

  String get uid => _auth.currentUser?.uid ?? '';

  /// Stream of current user's data (real-time)
  Stream<UserModel?> get userStream {
    if (uid.isEmpty) return const Stream.empty();
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      _currentUserData = UserModel.fromFirestore(doc);
      return _currentUserData;
    });
  }

  /// Add points and check for badge upgrades
  Future<void> addPoints(int points) async {
    if (uid.isEmpty) return;
    final docRef = _db.collection('users').doc(uid);
    await docRef.update({
      'cleanlinessScore': FieldValue.increment(points),
    });

    // Check badge eligibility
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

  /// Ward leaderboard (top 10 citizens)
  Future<List<UserModel>> getWardLeaderboard(String ward) async {
    final query = await _db
        .collection('users')
        .where('ward', isEqualTo: ward)
        .orderBy('cleanlinessScore', descending: true)
        .limit(10)
        .get();
    return query.docs.map((d) => UserModel.fromFirestore(d)).toList();
  }

  /// Overall leaderboard
  Future<List<UserModel>> getTopCitizens() async {
    final query = await _db
        .collection('users')
        .orderBy('cleanlinessScore', descending: true)
        .limit(20)
        .get();
    return query.docs.map((d) => UserModel.fromFirestore(d)).toList();
  }
}
