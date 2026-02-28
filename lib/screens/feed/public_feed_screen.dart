import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/complaint_service.dart';
import '../../services/user_service.dart';
import '../public_board/public_board_screen.dart';

class PublicFeedScreen extends StatelessWidget {
  const PublicFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.read<ComplaintService>();
    final userSvc = context.read<UserService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('✨ Resolved Issues'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Public Board',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PublicBoardScreen()),
            ),
          )
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: userSvc.userStream,
        builder: (context, userSnap) {
          final ward = userSnap.data?.ward;
          return StreamBuilder<List<ComplaintModel>>(
            stream: svc.publicFeed(ward: ward),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return Center(
                    child: Text(
                  ward == null
                      ? 'No resolved complaints yet.'
                      : 'No resolved complaints yet in $ward.',
                  style: const TextStyle(color: Colors.grey),
                ));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final c = list[i];
                  return _ResolvedFeedCard(c: c);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ResolvedFeedCard extends StatelessWidget {
  final ComplaintModel c;
  const _ResolvedFeedCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final hasAfter = c.imageAfterUrl != null && c.imageAfterUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Before / After images
          if (c.imageBeforeUrl.isNotEmpty || hasAfter)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: hasAfter
                  ? _BeforeAfterRow(
                      beforeUrl: c.imageBeforeUrl,
                      afterUrl: c.imageAfterUrl!)
                  : Image.network(
                      c.imageBeforeUrl,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                            height: 140,
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image,
                                color: Colors.grey),
                          )),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('✅', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(c.category,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    if (c.resolutionBadge != null && c.resolutionBadge!.isNotEmpty)
                      _BadgeChip(badge: c.resolutionBadge!),
                    const SizedBox(width: 6),
                    Text(c.ward,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
                if (c.resolutionTimeHours != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Resolved in ${c.resolutionTimeHours!.toStringAsFixed(1)} hours',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BeforeAfterRow extends StatelessWidget {
  final String beforeUrl;
  final String afterUrl;
  const _BeforeAfterRow(
      {required this.beforeUrl, required this.afterUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Row(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(beforeUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image,
                            color: Colors.grey))),
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4)),
                    child: const Text('Before',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 3, color: Colors.white),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(afterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image,
                            color: Colors.grey))),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4)),
                    child: const Text('After',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg)),
    );
  }
}
