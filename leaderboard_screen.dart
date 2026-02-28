import 'package:flutter/material.dart';
import '../../services/points_service.dart';
import '../../utils/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<WardLeaderboard> _wardLeaderboard = [];
  List<UserLeaderboard> _userLeaderboard = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final wards = await PointsService.getWardLeaderboard();
    final users = await PointsService.getUserLeaderboard();
    if (mounted) {
      setState(() {
        _wardLeaderboard = wards;
        _userLeaderboard = users;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: AppTheme.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: '🏙️ Ward Rankings'),
            Tab(text: '👤 Citizens'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWardLeaderboard(),
                _buildUserLeaderboard(),
              ],
            ),
    );
  }

  Widget _buildWardLeaderboard() {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildTop3Wards()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  if (i >= _wardLeaderboard.length - 3) return null;
                  return _buildWardRow(_wardLeaderboard[i + 3]);
                },
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _buildTop3Wards() {
    if (_wardLeaderboard.length < 3) return const SizedBox.shrink();
    final top3 = _wardLeaderboard.take(3).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.surface, AppTheme.bg],
        ),
      ),
      child: Column(
        children: [
          const Text(
            '🏆 This Month\'s Clean Wards',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd place
              Expanded(child: _buildPodiumCard(top3[1], 2, 80)),
              const SizedBox(width: 8),
              // 1st place
              Expanded(child: _buildPodiumCard(top3[0], 1, 110)),
              const SizedBox(width: 8),
              // 3rd place
              Expanded(child: _buildPodiumCard(top3[2], 3, 65)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumCard(WardLeaderboard ward, int rank, double height) {
    final colors = {
      1: AppTheme.accent,
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };
    final icons = {1: '🥇', 2: '🥈', 3: '🥉'};
    final color = colors[rank]!;

    return Column(
      children: [
        Text(icons[rank]!, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text(
          ward.ward,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text('${ward.score}', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withOpacity(0.4), color.withOpacity(0.1)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(
            child: Text('#$rank',
                style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _buildWardRow(WardLeaderboard ward) {
    final changeColor = ward.change > 0
        ? AppTheme.success
        : ward.change < 0
            ? AppTheme.error
            : AppTheme.textMuted;
    final changeIcon = ward.change > 0
        ? Icons.arrow_upward_rounded
        : ward.change < 0
            ? Icons.arrow_downward_rounded
            : Icons.remove_rounded;

    return GestureDetector(
      onTap: () => _showWardDetails(ward),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '#${ward.rank}',
                style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('🏙️', style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ward.ward,
                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    '${ward.resolved}/${ward.complaints} resolved',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${ward.score}',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 18)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(changeIcon, color: changeColor, size: 12),
                    Text(
                      ward.change == 0 ? '—' : '${ward.change.abs()}',
                      style: TextStyle(color: changeColor, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserLeaderboard() {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _userLeaderboard.length,
        itemBuilder: (ctx, i) => _buildUserRow(_userLeaderboard[i]),
      ),
    );
  }

  Widget _buildUserRow(UserLeaderboard user) {
    final isTopThree = user.rank <= 3;
    final rankColor = user.rank == 1
        ? AppTheme.accent
        : user.rank == 2
            ? const Color(0xFFC0C0C0)
            : user.rank == 3
                ? const Color(0xFFCD7F32)
                : AppTheme.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isTopThree ? AppTheme.card : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTopThree ? rankColor.withOpacity(0.3) : AppTheme.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '#${user.rank}',
                style: TextStyle(color: rankColor, fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(user.badge, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                Row(
                  children: [
                    Text('Ward ${user.ward}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    if (user.streak > 0) ...[
                      const SizedBox(width: 8),
                      Text('🔥 ${user.streak}d',
                          style: const TextStyle(color: AppTheme.accentOrange, fontSize: 11)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${user.points} pts',
            style: TextStyle(
              color: isTopThree ? rankColor : AppTheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  void _showWardDetails(WardLeaderboard ward) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🏙️', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Text(ward.ward,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Score: ${ward.score}',
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildDetailStat('Complaints', ward.complaints.toString(), AppTheme.warning)),
                const SizedBox(width: 12),
                Expanded(child: _buildDetailStat('Resolved', ward.resolved.toString(), AppTheme.success)),
                const SizedBox(width: 12),
                Expanded(child: _buildDetailStat('Rank Change',
                    ward.change > 0 ? '+${ward.change}' : ward.change.toString(),
                    ward.change >= 0 ? AppTheme.success : AppTheme.error)),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/complaint');
              },
              icon: const Icon(Icons.report_rounded),
              label: Text('Report issue in ${ward.ward}'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
