import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final userSvc = context.read<UserService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sign Out?'),
                  content: const Text('You will need to log in again.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign Out',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (ok == true) await auth.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: userSvc.userStream,
        builder: (context, snap) {
          final u = snap.data;
          if (u == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        child: Text(
                          u.name.isNotEmpty
                              ? u.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B5E20)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(u.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      Text(u.ward,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(u.badgeLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stats
                Row(
                  children: [
                    _St('${u.cleanlinessScore}', 'Points', '⭐',
                        Colors.amber),
                    const SizedBox(width: 10),
                    _St('${u.totalComplaints}', 'Reports', '📋',
                        Colors.blue),
                    const SizedBox(width: 10),
                    _St('${u.resolvedComplaints}', 'Resolved', '✅',
                        Colors.green),
                  ],
                ),
                const SizedBox(height: 16),

                // Badges
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Badges',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Badge('🌱', 'Beginner', 'Always', true),
                          _Badge('🥉', 'Bronze', '30 pts',
                              u.badges.contains('bronze')),
                          _Badge('🥈', 'Silver', '100 pts',
                              u.badges.contains('silver')),
                          _Badge('🥇', 'Gold', '200 pts',
                              u.badges.contains('gold')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Leaderboard
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${u.ward} Leaderboard',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 10),
                      FutureBuilder<List<UserModel>>(
                        future: userSvc.getLeaderboard(u.ward),
                        builder: (context, s) {
                          final list = s.data ?? [];
                          return Column(
                            children: list.asMap().entries.map((e) {
                              final rank = e.key + 1;
                              final lu = e.value;
                              final isMe = lu.id == userSvc.uid;
                              return Container(
                                margin:
                                    const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? const Color(0xFF1B5E20)
                                          .withOpacity(0.08)
                                      : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Text(rank == 1
                                        ? '🥇'
                                        : rank == 2
                                            ? '🥈'
                                            : rank == 3
                                                ? '🥉'
                                                : '#$rank'),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: Text(
                                            lu.name +
                                                (isMe ? ' (You)' : ''),
                                            style: TextStyle(
                                                fontWeight: isMe
                                                    ? FontWeight.w700
                                                    : FontWeight.normal))),
                                    Text('${lu.cleanlinessScore} pts',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color:
                                                Color(0xFF1B5E20))),
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

class _St extends StatelessWidget {
  final String v, l, icon;
  final Color c;
  const _St(this.v, this.l, this.icon, this.c);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(v,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: c)),
            Text(l,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ),
      );
}

class _Badge extends StatelessWidget {
  final String emoji, label, req;
  final bool earned;
  const _Badge(this.emoji, this.label, this.req, this.earned);
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(emoji,
            style: TextStyle(
                fontSize: 30,
                color: earned ? null : Colors.grey.withOpacity(0.3))),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: earned ? Colors.black87 : Colors.grey)),
        Text(req,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ]);
}
