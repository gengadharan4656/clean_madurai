// lib/screens/public_board/public_board_screen.dart
// NEW FILE – Read-only public board: resolved complaints, ward score, top citizens
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PublicBoardScreen extends StatelessWidget {
  const PublicBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Board'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F7F0),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Container(
              color: const Color(0xFF1B5E20),
              child: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(text: 'Resolved'),
                  Tab(text: 'Ward Scores'),
                  Tab(text: 'Top Citizens'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _ResolvedTab(),
                  _WardScoreTab(),
                  _TopCitizensTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab 1: Recently Resolved Complaints ─────────────────────────────────────
class _ResolvedTab extends StatelessWidget {
  const _ResolvedTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('status', isEqualTo: 'resolved')
          .orderBy('resolvedAt', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text('No resolved complaints yet.',
                style: TextStyle(color: Colors.grey)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data();
            return _ResolvedCard(data: d, id: docs[i].id);
          },
        );
      },
    );
  }
}

class _ResolvedCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String id;
  const _ResolvedCard({required this.data, required this.id});

  @override
  Widget build(BuildContext context) {
    final before = data['imageBeforeUrl'] as String? ?? '';
    final after = data['imageAfterUrl'] as String? ?? '';
    final badge = data['resolutionBadge'] as String? ?? '';
    final hours = (data['resolutionTimeHours'] as num?)?.toDouble();
    final category = data['category'] as String? ?? 'Issue';
    final ward = data['ward'] as String? ?? '';
    final resolvedAt = (data['resolvedAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('$category • $ward',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                if (badge.isNotEmpty) _BadgeChip(badge: badge),
                const SizedBox(width: 6),
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const Text(' Resolved',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (before.isNotEmpty || after.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Before',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.red)),
                        const SizedBox(height: 4),
                        _ImageBox(url: before),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward,
                        color: Color(0xFF1B5E20), size: 20),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('After',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green)),
                        const SizedBox(height: 4),
                        after.isNotEmpty
                            ? _ImageBox(url: after)
                            : Container(
                                height: 90,
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Center(
                                    child: Text('No image',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey))),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(
              children: [
                if (hours != null) ...[
                  const Icon(Icons.timer, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${hours.toStringAsFixed(1)} hrs to resolve',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                ],
                if (resolvedAt != null) ...[
                  const Icon(Icons.calendar_today,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(resolvedAt),
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _BadgeChip extends StatelessWidget {
  final String badge;
  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (badge) {
      case 'Fast':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        label = '⚡ Fast';
        break;
      case 'Normal':
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF57F17);
        label = '✅ Normal';
        break;
      default:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        label = '🐢 Delayed';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _ImageBox extends StatelessWidget {
  final String url;
  const _ImageBox({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        height: 90,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 90,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }
}

// ── Tab 2: Ward Cleanliness Scores ─────────────────────────────────────────
class _WardScoreTab extends StatelessWidget {
  const _WardScoreTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _computeWardScores(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final scores = snap.data ?? {};
        if (scores.isEmpty) {
          return const Center(
              child: Text('No data yet.', style: TextStyle(color: Colors.grey)));
        }
        final sorted = scores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: sorted.length,
          itemBuilder: (_, i) {
            final e = sorted[i];
            final pct = (e.value / 100).clamp(0.0, 1.0);
            final color = e.value >= 70
                ? Colors.green
                : e.value >= 40
                    ? Colors.orange
                    : Colors.red;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            Text('${e.value}%',
                                style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: Colors.grey.shade200,
                            color: color,
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, int>> _computeWardScores() async {
    final all = await FirebaseFirestore.instance
        .collection('complaints')
        .get();

    final wardTotal = <String, int>{};
    final wardResolved = <String, int>{};

    for (final doc in all.docs) {
      final d = doc.data();
      final ward = d['ward'] as String? ?? 'Unknown';
      final status = d['status'] as String? ?? '';
      wardTotal[ward] = (wardTotal[ward] ?? 0) + 1;
      if (status == 'resolved') {
        wardResolved[ward] = (wardResolved[ward] ?? 0) + 1;
      }
    }

    final scores = <String, int>{};
    for (final w in wardTotal.keys) {
      final total = wardTotal[w] ?? 1;
      final resolved = wardResolved[w] ?? 0;
      scores[w] = ((resolved / total) * 100).round();
    }
    return scores;
  }
}

// ── Tab 3: Top Contributing Citizens ───────────────────────────────────────
class _TopCitizensTab extends StatelessWidget {
  const _TopCitizensTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'citizen')
          .orderBy('cleanlinessScore', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
              child: Text('No data yet.', style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data();
            final name = d['name'] as String? ?? 'Anonymous';
            final ward = d['ward'] as String? ?? '';
            final score = d['cleanlinessScore'] as int? ?? 0;
            final complaints = d['totalComplaints'] as int? ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _rankColor(i).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        i < 3 ? ['🥇', '🥈', '🥉'][i] : '${i + 1}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        Text(ward,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('⭐ $score pts',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF57F17))),
                      Text('$complaints reports',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _rankColor(int i) {
    if (i == 0) return Colors.amber;
    if (i == 1) return Colors.blueGrey;
    if (i == 2) return Colors.brown;
    return Colors.grey;
  }
}
