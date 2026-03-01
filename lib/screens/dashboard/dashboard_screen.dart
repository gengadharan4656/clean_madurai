import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../features/dustbin/dustbin_finder.dart';
import '../../i18n/strings.dart';

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
                                  '${S.of(context, 'dash_hello')}, ${user?.name.split(' ').first ?? S.of(context, 'dash_citizen')} 👋',
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
                                        '${user?.cleanlinessScore ?? 0} ${S.of(context, 'dash_pts')}',
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
                            S.of(context, 'dash_reports'), const Color(0xFFE3F2FD)),
                        const SizedBox(width: 10),
                        _Stat('✅', '${user?.resolvedComplaints ?? 0}',
                            S.of(context, 'dash_resolved'), const Color(0xFFE8F5E9)),
                        const SizedBox(width: 10),
                        _Stat('⭐', '${user?.cleanlinessScore ?? 0}',
                            S.of(context, 'dash_points'), const Color(0xFFFFF8E1)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Ward summary
                    _WardCard(ward: user?.ward ?? 'Ward 1'),
                    const SizedBox(height: 20),

                    _DegradableCheckerCard(),
                    const SizedBox(height: 20),
                    const SizedBox(height: 8),
                    const FindNearbyDustbinButton(),
                    const SizedBox(height: 20),

                    // Recent complaints
                    Text(S.of(context, 'dash_recent_activity'),
                        style: const TextStyle(
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

// -------------------- Degradable / Non-degradable Checker --------------------

class _DegradableCheckerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _DegradableCheckerSheet(),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.eco, color: Color(0xFF1B5E20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context, 'checker_title'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.of(context, 'checker_subtitle'),
                    style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _DegradableCheckerSheet extends StatefulWidget {
  const _DegradableCheckerSheet();

  @override
  State<_DegradableCheckerSheet> createState() => _DegradableCheckerSheetState();
}

class _DegradableCheckerSheetState extends State<_DegradableCheckerSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  WasteResult? _result;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _check() async {
    final input = _ctrl.text.trim();
    if (input.isEmpty) {
      _snack(S.of(context, 'checker_snack_empty'));
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
    });

    // tiny delay to show loader smooth (optional)
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final res = WasteClassifier.classify(input);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = res;
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              S.of(context, 'checker_sheet_title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              S.of(context, 'checker_sheet_desc'),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _check(),
              decoration: InputDecoration(
                hintText: S.of(context, 'checker_hint'),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _loading ? null : _check,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _check,
                child: _loading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  S.of(context, 'checker_btn'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 12),
              _ResultBox(result: _result!),
            ],
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  final WasteResult result;
  const _ResultBox({required this.result});

  @override
  Widget build(BuildContext context) {
    final bg = result.type == WasteType.biodegradable
        ? Colors.green.withOpacity(0.08)
        : result.type == WasteType.nonBiodegradable
        ? Colors.orange.withOpacity(0.08)
        : Colors.blueGrey.withOpacity(0.08);

    final border = result.type == WasteType.biodegradable
        ? Colors.green.withOpacity(0.25)
        : result.type == WasteType.nonBiodegradable
        ? Colors.orange.withOpacity(0.25)
        : Colors.blueGrey.withOpacity(0.25);

    final label = _maybeTranslate(context, result.label);
    final tip = result.tip == null ? null : _maybeTranslate(context, result.tip!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          if (result.examples != null && result.examples!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${S.of(context, 'checker_examples')}: ${result.examples!.take(5).join(', ')}',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
          if (tip != null) ...[
            const SizedBox(height: 6),
            Text(
              tip,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  String _maybeTranslate(BuildContext context, String textOrKey) {
    // If WasteClassifier returns a key like 'checker_bio_label', translate it.
    // If it returns plain English (existing behaviour), keep it.
    final translated = S.of(context, textOrKey);
    if (translated == textOrKey) return textOrKey; // not found => original text
    return translated;
  }
}

// -------------------- Classifier + Larger Dataset --------------------

enum WasteType { biodegradable, nonBiodegradable, unknown }

class WasteResult {
  final WasteType type;
  final String label;
  final String? tip;
  final List<String>? examples;
  const WasteResult({
    required this.type,
    required this.label,
    this.tip,
    this.examples,
  });
}

class WasteClassifier {
  static bool _loaded = false;
  static final Set<String> _bio = {};
  static final Set<String> _nonBio = {};

  /// Call once (app start) OR lazy-load inside classify()
  static Future<void> loadDataset() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/waste_dataset.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;

    final bioList = (data['biodegradable'] as List).cast<String>();
    final nonList = (data['non_biodegradable'] as List).cast<String>();

    _bio.addAll(bioList.map(_normalize));
    _nonBio.addAll(nonList.map(_normalize));

    _loaded = true;
  }

  static WasteResult classify(String rawInput) {
    final input = _normalize(rawInput);

    // ✅ Lazy-load (works even if you didn't call loadDataset() earlier)
    // NOTE: this is sync, so we can't await here.
    // Best practice: call WasteClassifier.loadDataset() in app startup.
    if (!_loaded) {
      return const WasteResult(
        type: WasteType.unknown,
        // ✅ key-based (will translate)
        label: 'checker_loading_label',
        tip: 'checker_loading_tip',
        examples: ['banana peel', 'plastic bottle', 'battery', 'glass'],
      );
    }

    if (_bio.contains(input)) return _resultFor(WasteType.biodegradable);
    if (_nonBio.contains(input)) return _resultFor(WasteType.nonBiodegradable);

    // Optional: contains matching for partial inputs
    if (_bio.any((x) => x.contains(input) || input.contains(x))) {
      return _resultFor(WasteType.biodegradable);
    }
    if (_nonBio.any((x) => x.contains(input) || input.contains(x))) {
      return _resultFor(WasteType.nonBiodegradable);
    }

    return const WasteResult(
      type: WasteType.unknown,
      // ✅ key-based (will translate)
      label: 'checker_unknown_label',
      tip: 'checker_unknown_tip',
      examples: ['banana peel', 'paper', 'plastic bottle', 'battery', 'glass jar'],
    );
  }

  static WasteResult _resultFor(WasteType type) {
    switch (type) {
      case WasteType.biodegradable:
        return const WasteResult(
          type: WasteType.biodegradable,
          // ✅ key-based (will translate)
          label: 'checker_bio_label',
          tip: 'checker_bio_tip',
          examples: ['banana peel', 'vegetable waste', 'food leftovers', 'tea leaves', 'paper'],
        );
      case WasteType.nonBiodegradable:
        return const WasteResult(
          type: WasteType.nonBiodegradable,
          // ✅ key-based (will translate)
          label: 'checker_nonbio_label',
          tip: 'checker_nonbio_tip',
          examples: ['plastic bottle', 'chips packet', 'thermocol', 'glass jar', 'metal can'],
        );
      case WasteType.unknown:
        return const WasteResult(type: WasteType.unknown, label: 'checker_unknown_label');
    }
  }

  static String _normalize(String s) {
    final lower = s.toLowerCase().trim();
    final cleaned = lower.replaceAll(RegExp(r'[^a-z0-9\s-]'), ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
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
                  Text(S.of(context, 'dash_see_dirty'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(S.of(context, 'dash_tap_report_tab'),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(S.of(context, 'dash_report_now'),
                        style: const TextStyle(
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
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
            .where((d) => (d.data() as Map)['status'] == 'resolved')
            .length;
        final score = total == 0 ? 100 : ((resolved / total) * 100).round();

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
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: score > 70
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${S.of(context, 'dash_score')}: $score%',
                        style: TextStyle(
                          color: score > 70 ? Colors.green : Colors.orange,
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
                  _WS('$total', S.of(context, 'dash_total'), Colors.blue),
                  _WS('${total - resolved}', S.of(context, 'dash_pending'), Colors.orange),
                  _WS('$resolved', S.of(context, 'dash_resolved'), Colors.green),
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
    Text(l, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
            child: Center(
              child: Text(S.of(context, 'dash_no_reports_yet'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
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
            }[status] ??
                Colors.grey;
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
                        Text(_localizeCategory(context, d['category'] ?? 'Unknown'),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
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
      case 'Garbage Overflow':
        return '🗑️';
      case 'Open Dumping':
        return '♻️';
      case 'Sewer Blockage':
        return '🚰';
      case 'Public Toilet Issue':
        return '🚽';
      default:
        return '📋';
    }
  }

  String _localizeCategory(BuildContext context, String category) {
    // Map Firestore stored English category -> localized label using your existing keys
    switch (category) {
      case 'Garbage Overflow':
        return S.of(context, 'cat_garbage_overflow');
      case 'Open Dumping':
        return S.of(context, 'cat_open_dumping');
      case 'Sewer Blockage':
        return S.of(context, 'cat_sewer_blockage');
      case 'Public Toilet Issue':
        return S.of(context, 'cat_public_toilet');
      case 'Littering':
        return S.of(context, 'cat_littering');
      case 'Other':
        return S.of(context, 'cat_other');
      default:
      // if unknown, keep as-is
        return category;
    }
  }
}