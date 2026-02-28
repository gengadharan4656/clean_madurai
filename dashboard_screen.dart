import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'Week';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Mock analytics data
  final _weeklyComplaints = [14, 22, 18, 30, 25, 19, 28];
  final _weeklyResolved = [10, 18, 15, 26, 22, 17, 25];
  final _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final _wardScores = [
    {'name': 'Anna Nagar', 'score': 94, 'color': AppTheme.success},
    {'name': 'KK Nagar', 'score': 91, 'color': AppTheme.primary},
    {'name': 'Tallakulam', 'score': 88, 'color': AppTheme.accentBlue},
    {'name': 'Teppakulam', 'score': 85, 'color': AppTheme.accent},
    {'name': 'Arappalayam', 'score': 82, 'color': AppTheme.warning},
    {'name': 'Goripalayam', 'score': 76, 'color': AppTheme.accentOrange},
    {'name': 'Sellur', 'score': 71, 'color': AppTheme.error},
  ];

  final _wasteCategories = [
    {'name': 'Plastic', 'percent': 35.0, 'color': AppTheme.accentBlue},
    {'name': 'Organic', 'percent': 28.0, 'color': AppTheme.success},
    {'name': 'Paper', 'percent': 18.0, 'color': AppTheme.accent},
    {'name': 'Metal', 'percent': 10.0, 'color': AppTheme.warning},
    {'name': 'Other', 'percent': 9.0, 'color': AppTheme.textMuted},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: AppTheme.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: ['Week', 'Month', 'Year'].map((p) {
                final isSelected = _selectedPeriod == p;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPeriod = p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p,
                      style: TextStyle(
                        color: isSelected ? AppTheme.bg : AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Complaints'),
            Tab(text: 'Wards'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildComplaintsTab(),
          _buildWardsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // KPI Cards
          Row(
            children: [
              Expanded(child: _buildKpiCard('Total Reports', '1,248', '+12%', AppTheme.primary, Icons.report_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildKpiCard('Resolved', '1,089', '+18%', AppTheme.success, Icons.check_circle_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildKpiCard('Pending', '159', '-5%', AppTheme.warning, Icons.pending_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildKpiCard('Avg Time', '4.2h', '-1.1h', AppTheme.accentBlue, Icons.timer_rounded)),
            ],
          ),
          const SizedBox(height: 20),

          // Weekly Trend Chart
          _buildSectionTitle('Weekly Complaints Trend'),
          const SizedBox(height: 12),
          _buildBarChart(),
          const SizedBox(height: 20),

          // Waste Category Pie
          _buildSectionTitle('Waste Category Breakdown'),
          const SizedBox(height: 12),
          _buildPieChart(),
          const SizedBox(height: 20),

          // n8n Activity Log
          _buildSectionTitle('Automation Activity (n8n)'),
          const SizedBox(height: 12),
          _buildN8nActivityLog(),
        ],
      ),
    );
  }

  Widget _buildComplaintsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionTitle('Complaint Status Distribution'),
          const SizedBox(height: 12),
          _buildStatusDonut(),
          const SizedBox(height: 20),
          _buildSectionTitle('Resolution Time by Ward'),
          const SizedBox(height: 12),
          _buildHorizontalBarChart(),
          const SizedBox(height: 20),
          _buildSectionTitle('Severity Heatmap'),
          const SizedBox(height: 12),
          _buildSeverityGrid(),
        ],
      ),
    );
  }

  Widget _buildWardsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionTitle('Ward Cleanliness Score'),
          const SizedBox(height: 12),
          ..._wardScores.asMap().entries.map((e) {
            final ward = e.value;
            return _buildWardScoreRow(
              ward['name'] as String,
              ward['score'] as int,
              e.key + 1,
              ward['color'] as Color,
            );
          }),
          const SizedBox(height: 20),
          _buildSectionTitle('Monthly Performance Trend'),
          const SizedBox(height: 12),
          _buildLineChart(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CHART WIDGETS
  // ─────────────────────────────────────────────────────────────

  Widget _buildBarChart() {
    return _buildChartCard(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 35,
          gridData: FlGridData(
            show: true,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (v) => FlLine(color: AppTheme.cardBorder, strokeWidth: 0.5),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) => Text(
                  _weekDays[v.toInt()],
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, meta) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: List.generate(_weeklyComplaints.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: _weeklyComplaints[i].toDouble(),
                  color: AppTheme.primary.withOpacity(0.7),
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: _weeklyResolved[i].toDouble(),
                  color: AppTheme.success.withOpacity(0.5),
                  width: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return _buildChartCard(
      height: 260,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: _wasteCategories.map((cat) {
                  return PieChartSectionData(
                    value: cat['percent'] as double,
                    color: cat['color'] as Color,
                    radius: 60,
                    title: '${(cat['percent'] as double).round()}%',
                    titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  );
                }).toList(),
                sectionsSpace: 3,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _wasteCategories.map((cat) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: cat['color'] as Color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(cat['name'] as String,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDonut() {
    return _buildChartCard(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(value: 87, color: AppTheme.success, title: '87%',
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  PieChartSectionData(value: 8, color: AppTheme.warning, title: '8%',
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  PieChartSectionData(value: 5, color: AppTheme.error, title: '5%',
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ],
                sectionsSpace: 3,
                centerSpaceRadius: 50,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem('Resolved', AppTheme.success, '1,089'),
              const SizedBox(height: 8),
              _buildLegendItem('In Progress', AppTheme.warning, '100'),
              const SizedBox(height: 8),
              _buildLegendItem('Overdue', AppTheme.error, '59'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalBarChart() {
    final data = [
      {'ward': 'Anna Nagar', 'hours': 2.1, 'color': AppTheme.success},
      {'ward': 'KK Nagar', 'hours': 3.5, 'color': AppTheme.primary},
      {'ward': 'Tallakulam', 'hours': 4.2, 'color': AppTheme.accentBlue},
      {'ward': 'Teppakulam', 'hours': 5.8, 'color': AppTheme.warning},
      {'ward': 'Goripalayam', 'hours': 8.4, 'color': AppTheme.error},
    ];
    return _buildChartCard(
      height: 180,
      child: Column(
        children: data.map((d) {
          final pct = ((d['hours'] as double) / 10).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(d['ward'] as String,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppTheme.cardBorder,
                      color: d['color'] as Color,
                      minHeight: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${d['hours']}h',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSeverityGrid() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final hours = List.generate(8, (i) => '${6 + i * 2}:00');
    final data = List.generate(
        8, (_) => List.generate(7, (_) => (3 + (DateTime.now().millisecond % 10))));

    return _buildChartCard(
      height: 200,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 40),
              ...days.map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hours.length,
              itemBuilder: (ctx, hi) => Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(hours[hi],
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 8)),
                  ),
                  ...List.generate(7, (di) {
                    final v = data[hi][di];
                    final opacity = (v / 12).clamp(0.1, 1.0);
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(1),
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(opacity),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return _buildChartCard(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (v) => FlLine(color: AppTheme.cardBorder, strokeWidth: 0.5),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                  final i = v.toInt();
                  if (i < 0 || i >= months.length) return const SizedBox.shrink();
                  return Text(months[i],
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10));
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 72), FlSpot(1, 78), FlSpot(2, 74),
                FlSpot(3, 82), FlSpot(4, 88), FlSpot(5, 91),
              ],
              isCurved: true,
              color: AppTheme.primary,
              barWidth: 2.5,
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primary.withOpacity(0.12),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.primary,
                  strokeWidth: 2,
                  strokeColor: AppTheme.bg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildN8nActivityLog() {
    final logs = [
      {'time': '6:00 AM', 'event': 'Morning alert sent to 12 collectors', 'type': 'morning', 'count': 12},
      {'time': '9:14 AM', 'event': 'Complaint trigger — Ward 5, KK Nagar', 'type': 'alert', 'count': 1},
      {'time': '11:32 AM', 'event': 'Pickup confirmed — Ward 3, Tallakulam', 'type': 'complete', 'count': 1},
      {'time': '2:05 PM', 'event': 'Ward status update sent — 50 wards', 'type': 'status', 'count': 50},
      {'time': '4:48 PM', 'event': 'Complaint trigger — Ward 1, Temple Area', 'type': 'alert', 'count': 1},
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: logs.asMap().entries.map((e) {
          final log = e.value;
          final isLast = e.key == logs.length - 1;
          final typeColor = log['type'] == 'morning'
              ? AppTheme.accentBlue
              : log['type'] == 'alert'
                  ? AppTheme.warning
                  : log['type'] == 'complete'
                      ? AppTheme.success
                      : AppTheme.textSecondary;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: !isLast
                  ? const Border(bottom: BorderSide(color: AppTheme.cardBorder))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: typeColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 56,
                  child: Text(log['time'] as String,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ),
                Expanded(
                  child: Text(log['event'] as String,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWardScoreRow(String name, int score, int rank, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: rank == 1 ? AppTheme.accent.withOpacity(0.4) : AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: rank <= 3 ? AppTheme.accent.withOpacity(0.15) : AppTheme.cardBorder.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('#$rank',
                  style: TextStyle(
                    color: rank <= 3 ? AppTheme.accent : AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          backgroundColor: AppTheme.cardBorder,
                          color: color,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$score', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, String change, Color color, IconData icon) {
    final isPositive = change.startsWith('+');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPositive ? AppTheme.success : AppTheme.error).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: isPositive ? AppTheme.success : AppTheme.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildChartCard({required Widget child, required double height}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: child,
    );
  }

  Widget _buildLegendItem(String label, Color color, String count) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(width: 4),
        Text(count, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 3, height: 18, color: AppTheme.primary,
            margin: const EdgeInsets.only(right: 10)),
        Text(title,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
