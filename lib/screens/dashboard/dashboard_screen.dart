import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = context.read<UserService>();

    return StreamBuilder<UserModel?>(
      stream: userService.userStream,
      builder: (context, userSnap) {
        final user = userSnap.data;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: const Color(0xFF1B5E20),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Hello, ${user?.name.split(' ').first ?? 'Citizen'} 👋',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star,
                                          color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${user?.cleanlinessScore ?? 0} pts',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(user?.ward ?? 'Madurai',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            Text(user?.badgeLabel ?? '🌱 Beginner',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Report button
                    _ReportCard(),
                    const SizedBox(height: 16),

                    // Stats
                    Row(
                      children: [
                        _Stat('📋', '${user?.totalComplaints ?? 0}',
                            'Reports', const Color(0xFFE3F2FD)),
                        const SizedBox(width: 10),
                        _Stat('✅', '${user?.resolvedComplaints ?? 0}',
                            'Resolved', const Color(0xFFE8F5E9)),
                        const SizedBox(width: 10),
                        _Stat('⭐', '${user?.cleanlinessScore ?? 0}',
                            'Points', const Color(0xFFFFF8E1)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Ward summary
                    _WardCard(ward: user?.ward ?? 'Ward 1'),
                    const SizedBox(height: 20),

                    // Recent complaints
                    const Text('Recent Activity',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    _RecentActivity(),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Switch to Report tab
        final scaffold = context.findAncestorStateOfType<State>();
        // Navigate to report - handled by bottom nav
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFF6D00), Color(0xFFFF8F00)]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('See something dirty?',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Tap Report tab below to submit',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Report Now →',
                        style: TextStyle(
                            color: Color(0xFFFF6D00),
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const Text('🗑️', style: TextStyle(fontSize: 56)),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String icon, value, label;
  final Color color;
  const _Stat(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _WardCard extends StatelessWidget {
  final String ward;
  const _WardCard({required this.ward});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('ward', isEqualTo: ward)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final total = docs.length;
        final resolved = docs
            .where((d) =>
                (d.data() as Map)['status'] == 'resolved')
            .length;
        final score = total == 0
            ? 100
            : ((resolved / total) * 100).round();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(ward,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: score > 70
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Score: $score%',
                        style: TextStyle(
                          color: score > 70
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                      score > 70 ? Colors.green : Colors.orange),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _WS('$total', 'Total', Colors.blue),
                  _WS('${total - resolved}', 'Pending',
                      Colors.orange),
                  _WS('$resolved', 'Resolved', Colors.green),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WS extends StatelessWidget {
  final String v, l;
  final Color c;
  const _WS(this.v, this.l, this.c);
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(v,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: c)),
        Text(l,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]);
}

class _RecentActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('No reports yet. Tap Report to get started!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
            ),
          );
        }
        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final status = d['status'] ?? 'submitted';
            final color = {
              'submitted': Colors.blue,
              'assigned': Colors.purple,
              'in_progress': Colors.orange,
              'resolved': Colors.green,
            }[status] ?? Colors.grey;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                        child: Text(_catEmoji(d['category'] ?? ''),
                            style: const TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['category'] ?? 'Unknown',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        Text('#${doc.id}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _catEmoji(String c) {
    switch (c) {
      case 'Garbage Overflow': return '🗑️';
      case 'Open Dumping': return '♻️';
      case 'Sewer Blockage': return '🚰';
      case 'Public Toilet Issue': return '🚽';
      default: return '📋';
    }
  }
}
