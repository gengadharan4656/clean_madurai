import 'package:flutter/material.dart';
import '../../services/points_service.dart';
import '../../utils/app_theme.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen>
    with TickerProviderStateMixin {
  late AnimationController _counterController;
  late Animation<double> _counterAnim;
  UserPoints _userPoints = UserPoints.empty();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _counterController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _counterAnim = CurvedAnimation(parent: _counterController, curve: Curves.easeOut);
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    final pts = await PointsService.getUserPoints();
    if (mounted) {
      setState(() {
        _userPoints = pts;
        _isLoading = false;
      });
      _counterController.forward();
    }
  }

  @override
  void dispose() {
    _counterController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _activities = [
    {'icon': '📸', 'activity': 'Photo submitted', 'points': '+5', 'time': '2h ago'},
    {'icon': '📋', 'activity': 'Complaint filed', 'points': '+10', 'time': '4h ago'},
    {'icon': '🔥', 'activity': '7-day streak bonus', 'points': '+25', 'time': '1d ago'},
    {'icon': '✅', 'activity': 'Complaint resolved', 'points': '+5', 'time': '2d ago'},
    {'icon': '📍', 'activity': 'Dustbin reported', 'points': '+15', 'time': '3d ago'},
    {'icon': '🌅', 'activity': 'Daily check-in', 'points': '+3', 'time': '4d ago'},
  ];

  final List<Map<String, dynamic>> _howToEarnList = [
    {'icon': '📸', 'activity': 'Submit complaint with photo', 'points': '10 pts'},
    {'icon': '📍', 'activity': 'Report full dustbin', 'points': '15 pts'},
    {'icon': '🌅', 'activity': 'Daily login', 'points': '3 pts'},
    {'icon': '🔥', 'activity': '7-day streak', 'points': '25 pts'},
    {'icon': '🏆', 'activity': '30-day streak', 'points': '100 pts'},
    {'icon': '✅', 'activity': 'Collector task complete', 'points': '60 pts'},
    {'icon': '🎯', 'activity': 'AI-verified before/after', 'points': '40 pts'},
    {'icon': '👑', 'activity': 'Monthly top ward', 'points': '200 pts'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('My Points'),
        backgroundColor: AppTheme.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPointsHero(),
                  const SizedBox(height: 20),
                  _buildStreakCard(),
                  const SizedBox(height: 20),
                  _buildBadgeSection(),
                  const SizedBox(height: 20),
                  _buildHowToEarnSection(),
                  const SizedBox(height: 20),
                  _buildRecentActivity(),
                ],
              ),
            ),
    );
  }

  Widget _buildPointsHero() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withOpacity(0.2),
            AppTheme.primaryDark.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedBuilder(
                animation: _counterAnim,
                builder: (ctx, child) {
                  final displayPoints = (_userPoints.total * _counterAnim.value).round();
                  return Text(
                    '$displayPoints',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(' pts',
                    style: TextStyle(color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _userPoints.badge['name'] ?? 'Clean Newcomer',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Level ${_userPoints.level} • Rank #${_userPoints.rank == 0 ? '—' : _userPoints.rank}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          // Progress to next level
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level Progress', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Text('340 / 500 pts', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.68,
              backgroundColor: AppTheme.cardBorder,
              color: AppTheme.primary,
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.accentOrange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('🔥', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_userPoints.streak}-Day Streak',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userPoints.streak >= 7
                      ? 'Amazing! Keep it up!'
                      : 'Keep going to reach 7-day bonus!',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '+${_userPoints.streak >= 7 ? '25' : '3'}',
                style: const TextStyle(
                  color: AppTheme.accentOrange,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text('pts/day', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeSection() {
    final badges = [
      {'id': 'newcomer', 'name': 'Newcomer', 'icon': '🌱', 'unlocked': true, 'points': 0},
      {'id': 'activist', 'name': 'Activist', 'icon': '♻️', 'unlocked': _userPoints.total >= 100, 'points': 100},
      {'id': 'champion', 'name': 'Champion', 'icon': '🏆', 'unlocked': _userPoints.total >= 500, 'points': 500},
      {'id': 'guardian', 'name': 'Guardian', 'icon': '🛡️', 'unlocked': _userPoints.total >= 1000, 'points': 1000},
      {'id': 'hero', 'name': 'Hero', 'icon': '⭐', 'unlocked': _userPoints.total >= 2500, 'points': 2500},
      {'id': 'legend', 'name': 'Legend', 'icon': '👑', 'unlocked': _userPoints.total >= 5000, 'points': 5000},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Badges'),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            itemBuilder: (ctx, i) {
              final badge = badges[i];
              final unlocked = badge['unlocked'] as bool;
              return Container(
                width: 70,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: unlocked ? AppTheme.card : AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: unlocked ? AppTheme.primary.withOpacity(0.4) : AppTheme.cardBorder,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: unlocked ? 1.0 : 0.3,
                      child: Text(badge['icon'] as String,
                          style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge['name'] as String,
                      style: TextStyle(
                        color: unlocked ? AppTheme.textSecondary : AppTheme.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHowToEarnSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('How to Earn Points'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            children: _howToEarnList.asMap().entries.map((e) {
              final item = e.value;
              final isLast = e.key == _howToEarnList.length - 1;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: !isLast
                      ? const Border(bottom: BorderSide(color: AppTheme.cardBorder))
                      : null,
                ),
                child: Row(
                  children: [
                    Text(item['icon'] as String, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(item['activity'] as String,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item['points'] as String,
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Recent Activity'),
        const SizedBox(height: 12),
        ..._activities.map((activity) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                Text(activity['icon'], style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(activity['activity'],
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      activity['points'],
                      style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    Text(activity['time'],
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 3, height: 18, color: AppTheme.primary, margin: const EdgeInsets.only(right: 10)),
        Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
