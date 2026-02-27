// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = context.read<UserService>();
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sign Out?'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) await auth.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: userService.userStream,
        builder: (context, snap) {
          final user = snap.data;
          if (user == null) return const Center(child: CircularProgressIndicator());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, Color(0xFF2E7D32)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                      Text(user.ward, style: TextStyle(color: Colors.white.withOpacity(0.8))),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.badgeLabel,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stats
                Row(
                  children: [
                    _StatCard('${user.cleanlinessScore}', 'Points', '⭐', Colors.amber),
                    const SizedBox(width: 12),
                    _StatCard('${user.totalComplaints}', 'Reports', '📋', Colors.blue),
                    const SizedBox(width: 12),
                    _StatCard('${user.resolvedComplaints}', 'Resolved', '✅', Colors.green),
                  ],
                ),
                const SizedBox(height: 20),

                // Badges
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Badges', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _BadgeTile('🌱', 'Beginner', 'Always', true),
                          _BadgeTile('🥉', 'Bronze', '30+ pts', user.badges.contains('bronze')),
                          _BadgeTile('🥈', 'Silver', '100+ pts', user.badges.contains('silver')),
                          _BadgeTile('🥇', 'Gold', '200+ pts', user.badges.contains('gold')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Leaderboard
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${user.ward} Leaderboard', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 12),
                      FutureBuilder<List<UserModel>>(
                        future: userService.getWardLeaderboard(user.ward),
                        builder: (context, snap) {
                          final leaders = snap.data ?? [];
                          return Column(
                            children: leaders.asMap().entries.map((e) {
                              final rank = e.key + 1;
                              final u = e.value;
                              final isMe = u.id == userService.uid;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: isMe ? Border.all(color: AppTheme.primary.withOpacity(0.3)) : null,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '#$rank',
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        u.name + (isMe ? ' (You)' : ''),
                                        style: TextStyle(
                                          fontWeight: isMe ? FontWeight.w700 : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${u.cleanlinessScore} pts',
                                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label, icon;
  final Color color;
  const _StatCard(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMed)),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final String emoji, label, requirement;
  final bool earned;
  const _BadgeTile(this.emoji, this.label, this.requirement, this.earned);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: 32, color: earned ? null : Colors.grey.withOpacity(0.4)),
          ),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: earned ? AppTheme.textDark : Colors.grey)),
          Text(requirement, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          if (earned)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
