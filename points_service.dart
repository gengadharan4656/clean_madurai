import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Points & Gamification Service
class PointsService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Points values per activity
  static const Map<String, int> _pointsMap = {
    'complaint_submitted': 10,
    'complaint_resolved': 5,
    'image_uploaded': 5,
    'dustbin_reported': 15,
    'daily_login': 3,
    'streak_7_days': 25,
    'streak_30_days': 100,
    'ward_cleanup_participated': 50,
    'profile_complete': 20,
    'first_complaint': 20,
    'referred_user': 30,
    'before_after_verified': 40,
    'collector_task_complete': 60,
    'monthly_top_ward': 200,
  };

  static const Map<String, String> _activityDescriptions = {
    'complaint_submitted': 'Submitted a garbage complaint',
    'complaint_resolved': 'Your complaint was resolved',
    'image_uploaded': 'Uploaded evidence photo',
    'dustbin_reported': 'Reported a full dustbin',
    'daily_login': 'Daily check-in bonus',
    'streak_7_days': '7-day streak achieved! 🔥',
    'streak_30_days': '30-day streak! 🏆',
    'ward_cleanup_participated': 'Participated in ward cleanup',
    'profile_complete': 'Profile completed',
    'first_complaint': 'First complaint bonus',
    'referred_user': 'Referred a new user',
    'before_after_verified': 'Before/After verified by AI',
    'collector_task_complete': 'Collection task completed',
    'monthly_top_ward': 'Your ward ranked #1 this month!',
  };

  // Badge thresholds
  static const List<Map<String, dynamic>> _badges = [
    {'id': 'newcomer', 'name': 'Clean Newcomer', 'points': 0, 'icon': '🌱'},
    {'id': 'activist', 'name': 'Green Activist', 'points': 100, 'icon': '♻️'},
    {'id': 'champion', 'name': 'Clean Champion', 'points': 500, 'icon': '🏆'},
    {'id': 'guardian', 'name': 'City Guardian', 'points': 1000, 'icon': '🛡️'},
    {'id': 'hero', 'name': 'Madurai Hero', 'points': 2500, 'icon': '⭐'},
    {'id': 'legend', 'name': 'Clean Legend', 'points': 5000, 'icon': '👑'},
  ];

  // ─────────────────────────────────────────────────────────────
  // AWARD POINTS
  // ─────────────────────────────────────────────────────────────
  static Future<int> awardPoints({
    required String activity,
    String? userId,
    String? referenceId,
    int? customPoints,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return 0;

    final int points = customPoints ?? _pointsMap[activity] ?? 0;
    if (points == 0) return 0;

    try {
      final batch = _db.batch();

      // Update user points
      final userRef = _db.collection('users').doc(uid);
      batch.update(userRef, {
        'points': FieldValue.increment(points),
        'total_activities': FieldValue.increment(1),
        'last_activity': FieldValue.serverTimestamp(),
      });

      // Log transaction
      final txRef = _db
          .collection('users')
          .doc(uid)
          .collection('points_history')
          .doc();
      batch.set(txRef, {
        'activity': activity,
        'description': _activityDescriptions[activity] ?? activity,
        'points': points,
        'reference_id': referenceId,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      });

      await batch.commit();

      // Check and award badges
      await _checkAndAwardBadges(uid);

      // Update streak
      await _updateStreak(uid);

      return points;
    } catch (e) {
      print('Points award error: $e');
      return 0;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // GET USER POINTS
  // ─────────────────────────────────────────────────────────────
  static Future<UserPoints> getUserPoints({String? userId}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return UserPoints.empty();

    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return UserPoints.empty();

      final data = doc.data()!;
      return UserPoints(
        total: data['points'] ?? 0,
        streak: data['streak_days'] ?? 0,
        rank: data['rank'] ?? 0,
        badge: _getBadge(data['points'] ?? 0),
        level: _getLevel(data['points'] ?? 0),
      );
    } catch (e) {
      return UserPoints.empty();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // GET POINTS HISTORY
  // ─────────────────────────────────────────────────────────────
  static Stream<List<PointTransaction>> getPointsHistory({String? userId}) {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(uid)
        .collection('points_history')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PointTransaction.fromMap(d.data()))
            .toList());
  }

  // ─────────────────────────────────────────────────────────────
  // WARD LEADERBOARD
  // ─────────────────────────────────────────────────────────────
  static Future<List<WardLeaderboard>> getWardLeaderboard() async {
    try {
      final snap = await _db
          .collection('wards')
          .orderBy('clean_score', descending: true)
          .limit(20)
          .get();

      return snap.docs
          .asMap()
          .entries
          .map((e) => WardLeaderboard.fromMap(e.value.data(), e.key + 1))
          .toList();
    } catch (e) {
      // Return mock data for demo
      return _getMockLeaderboard();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // USER LEADERBOARD
  // ─────────────────────────────────────────────────────────────
  static Future<List<UserLeaderboard>> getUserLeaderboard(
      {String? ward}) async {
    try {
      Query query = _db.collection('users').orderBy('points', descending: true).limit(50);
      if (ward != null) {
        query = query.where('ward', isEqualTo: ward);
      }

      final snap = await query.get();
      return snap.docs
          .asMap()
          .entries
          .map((e) => UserLeaderboard.fromMap(
              e.value.data() as Map<String, dynamic>, e.key + 1))
          .toList();
    } catch (e) {
      return _getMockUserLeaderboard();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────
  static Future<void> _checkAndAwardBadges(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final int points = doc.data()?['points'] ?? 0;
    final List<dynamic> currentBadges = doc.data()?['badges'] ?? [];

    for (final badge in _badges) {
      if (points >= badge['points'] && !currentBadges.contains(badge['id'])) {
        await _db.collection('users').doc(uid).update({
          'badges': FieldValue.arrayUnion([badge['id']]),
          'current_badge': badge['id'],
        });
      }
    }
  }

  static Future<void> _updateStreak(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return;

    final lastLogin = (data['last_login'] as Timestamp?)?.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastLogin == null) {
      await _db.collection('users').doc(uid).update({
        'streak_days': 1,
        'last_login': FieldValue.serverTimestamp(),
      });
      return;
    }

    final lastDay =
        DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
    final diff = today.difference(lastDay).inDays;

    if (diff == 1) {
      // Continue streak
      final newStreak = (data['streak_days'] ?? 0) + 1;
      await _db.collection('users').doc(uid).update({
        'streak_days': newStreak,
        'last_login': FieldValue.serverTimestamp(),
      });
      // Award streak bonuses
      if (newStreak == 7) await awardPoints(activity: 'streak_7_days', userId: uid);
      if (newStreak == 30) await awardPoints(activity: 'streak_30_days', userId: uid);
    } else if (diff > 1) {
      // Reset streak
      await _db.collection('users').doc(uid).update({
        'streak_days': 1,
        'last_login': FieldValue.serverTimestamp(),
      });
    }
  }

  static Map<String, dynamic> _getBadge(int points) {
    Map<String, dynamic> badge = _badges.first;
    for (final b in _badges) {
      if (points >= b['points']) badge = b;
    }
    return badge;
  }

  static int _getLevel(int points) {
    return (points / 100).floor() + 1;
  }

  static List<WardLeaderboard> _getMockLeaderboard() {
    return [
      WardLeaderboard(rank: 1, ward: 'Anna Nagar', score: 94, complaints: 12, resolved: 12, change: 2),
      WardLeaderboard(rank: 2, ward: 'KK Nagar', score: 91, complaints: 18, resolved: 17, change: 0),
      WardLeaderboard(rank: 3, ward: 'Tallakulam', score: 88, complaints: 9, resolved: 8, change: 1),
      WardLeaderboard(rank: 4, ward: 'Teppakulam', score: 85, complaints: 15, resolved: 13, change: -1),
      WardLeaderboard(rank: 5, ward: 'Arappalayam', score: 82, complaints: 22, resolved: 18, change: 3),
    ];
  }

  static List<UserLeaderboard> _getMockUserLeaderboard() {
    return [
      UserLeaderboard(rank: 1, name: 'Rajesh K.', ward: 'Anna Nagar', points: 2450, badge: '⭐', streak: 15),
      UserLeaderboard(rank: 2, name: 'Priya M.', ward: 'KK Nagar', points: 1980, badge: '🏆', streak: 22),
      UserLeaderboard(rank: 3, name: 'Murugan R.', ward: 'Tallakulam', points: 1720, badge: '🏆', streak: 8),
      UserLeaderboard(rank: 4, name: 'Kavitha S.', ward: 'Teppakulam', points: 1560, badge: '🏆', streak: 12),
      UserLeaderboard(rank: 5, name: 'Senthil A.', ward: 'Arappalayam', points: 1340, badge: '♻️', streak: 5),
    ];
  }
}

// ─────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────
class UserPoints {
  final int total;
  final int streak;
  final int rank;
  final Map<String, dynamic> badge;
  final int level;

  const UserPoints({
    required this.total,
    required this.streak,
    required this.rank,
    required this.badge,
    required this.level,
  });

  factory UserPoints.empty() => UserPoints(
    total: 0, streak: 0, rank: 0,
    badge: {'id': 'newcomer', 'name': 'Clean Newcomer', 'points': 0, 'icon': '🌱'},
    level: 1,
  );
}

class PointTransaction {
  final String activity;
  final String description;
  final int points;
  final DateTime timestamp;

  const PointTransaction({
    required this.activity,
    required this.description,
    required this.points,
    required this.timestamp,
  });

  factory PointTransaction.fromMap(Map<String, dynamic> map) {
    return PointTransaction(
      activity: map['activity'] ?? '',
      description: map['description'] ?? '',
      points: map['points'] ?? 0,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class WardLeaderboard {
  final int rank;
  final String ward;
  final int score;
  final int complaints;
  final int resolved;
  final int change;

  const WardLeaderboard({
    required this.rank,
    required this.ward,
    required this.score,
    required this.complaints,
    required this.resolved,
    required this.change,
  });

  factory WardLeaderboard.fromMap(Map<String, dynamic> map, int rank) {
    return WardLeaderboard(
      rank: rank,
      ward: map['name'] ?? 'Ward $rank',
      score: map['clean_score'] ?? 0,
      complaints: map['total_complaints'] ?? 0,
      resolved: map['resolved_complaints'] ?? 0,
      change: map['rank_change'] ?? 0,
    );
  }
}

class UserLeaderboard {
  final int rank;
  final String name;
  final String ward;
  final int points;
  final String badge;
  final int streak;

  const UserLeaderboard({
    required this.rank,
    required this.name,
    required this.ward,
    required this.points,
    required this.badge,
    required this.streak,
  });

  factory UserLeaderboard.fromMap(Map<String, dynamic> map, int rank) {
    return UserLeaderboard(
      rank: rank,
      name: map['display_name'] ?? 'User $rank',
      ward: map['ward'] ?? '-',
      points: map['points'] ?? 0,
      badge: map['current_badge_icon'] ?? '🌱',
      streak: map['streak_days'] ?? 0,
    );
  }
}
