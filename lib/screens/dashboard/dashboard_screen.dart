// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../models/complaint_model.dart';
import '../report/report_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = context.read<UserService>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<UserModel?>(
        stream: userService.userStream,
        builder: (context, userSnap) {
          final user = userSnap.data;
          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primary, Color(0xFF2E7D32)],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello, ${user?.name.split(' ').first ?? 'Citizen'} 👋',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      user?.ward ?? 'Madurai',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${user?.cleanlinessScore ?? 0} pts',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user?.badgeLabel ?? '🌱 Beginner',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                            ),
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
                    // Quick Action - Report Button
                    _QuickReportCard(),
                    const SizedBox(height: 16),

                    // Stats Row
                    _StatsRow(user: user),
                    const SizedBox(height: 20),

                    // Ward Cleanliness
                    const Text(
                      'Ward Overview',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 12),
                    _WardStats(ward: user?.ward ?? 'Ward 1'),
                    const SizedBox(height: 20),

                    // Recent Complaints
                    const Text(
                      'Recent Activity',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 12),
                    _RecentComplaints(),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickReportCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.secondary, Color(0xFFFF8F00)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'See something dirty?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to report + earn +10 points',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Report Now →',
                      style: TextStyle(
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Text('🗑️', style: TextStyle(fontSize: 64)),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final UserModel? user;
  const _StatsRow({this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: '📋',
          value: '${user?.totalComplaints ?? 0}',
          label: 'Reports',
          color: const Color(0xFFE3F2FD),
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: '✅',
          value: '${user?.resolvedComplaints ?? 0}',
          label: 'Resolved',
          color: const Color(0xFFE8F5E9),
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: '⭐',
          value: '${user?.cleanlinessScore ?? 0}',
          label: 'Points',
          color: const Color(0xFFFFF8E1),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon, value, label;
  final Color color;

  const _StatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark),
            ),
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMed)),
          ],
        ),
      ),
    );
  }
}

class _WardStats extends StatelessWidget {
  final String ward;
  const _WardStats({required this.ward});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('ward', isEqualTo: ward)
          .snapshots(),
      builder: (context, snap) {
        final total = snap.data?.docs.length ?? 0;
        final resolved = snap.data?.docs
                .where((d) => (d.data() as Map)['status'] == 'resolved')
                .length ??
            0;
        final pending = total - resolved;
        final cleanScore = total == 0 ? 100 : ((resolved / total) * 100).round();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(ward, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cleanScore > 70
                          ? AppTheme.success.withOpacity(0.1)
                          : AppTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Score: $cleanScore%',
                      style: TextStyle(
                        color: cleanScore > 70 ? AppTheme.success : AppTheme.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: cleanScore / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    cleanScore > 70 ? AppTheme.success : AppTheme.warning,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _WardStat('$total', 'Total', Colors.blue),
                  _WardStat('$pending', 'Pending', Colors.orange),
                  _WardStat('$resolved', 'Resolved', Colors.green),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WardStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _WardStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMed)),
      ],
    );
  }
}

class _RecentComplaints extends StatelessWidget {
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
        if (!snap.hasData) return const SizedBox.shrink();
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Column(
                children: [
                  Text('🏙️', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 8),
                  Text('No reports yet.\nBe the first to report!', textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final status = d['status'] ?? 'submitted';
            final statusColors = {
              'submitted': Colors.blue,
              'assigned': Colors.purple,
              'in_progress': Colors.orange,
              'resolved': Colors.green,
            };
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (statusColors[status] ?? Colors.grey).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _categoryEmoji(d['category'] ?? ''),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d['category'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '#${doc.id}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMed),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (statusColors[status] ?? Colors.grey).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColors[status] ?? Colors.grey,
                      ),
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

  String _categoryEmoji(String category) {
    switch (category) {
      case 'Garbage overflow': return '🗑️';
      case 'Open dumping': return '♻️';
      case 'Sewer blockage': return '🚰';
      case 'Public toilet issue': return '🚽';
      default: return '📋';
    }
  }
}
