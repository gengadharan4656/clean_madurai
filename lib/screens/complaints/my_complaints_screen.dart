// ── MY COMPLAINTS ──────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/complaint_service.dart';

class MyComplaintsScreen extends StatelessWidget {
  const MyComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.read<ComplaintService>();
    return Scaffold(
      appBar: AppBar(title: const Text('My Reports'),
          automaticallyImplyLeading: false),
      body: StreamBuilder<List<ComplaintModel>>(
        stream: svc.myComplaints,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(
                child: Text('No reports yet.\nTap Report to submit one!',
                    textAlign: TextAlign.center));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) => _Card(c: list[i]),
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final ComplaintModel c;
  const _Card({required this.c});

  @override
  Widget build(BuildContext context) {
    final sColor = {
      'submitted': Colors.blue,
      'assigned': Colors.purple,
      'in_progress': Colors.orange,
      'resolved': Colors.green,
    }[c.status] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: c.imageBeforeUrl.isNotEmpty
                ? Image.network(c.imageBeforeUrl, width: 54, height: 54, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 54, height: 54, color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey)))
                : Container(width: 54, height: 54, color: Colors.grey.shade200),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.category, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('#${c.id}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                if (c.aiWasteType != null)
                  Text('🤖 ${c.aiWasteType}', style: const TextStyle(fontSize: 11, color: Colors.green)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: sColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(c.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: sColor)),
              ),
              const SizedBox(height: 4),
              Text(c.statusEmoji.split(' ').first, style: const TextStyle(fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }
}
