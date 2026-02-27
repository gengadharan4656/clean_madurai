// lib/screens/feed/public_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/complaint_service.dart';
import '../../models/complaint_model.dart';

class PublicFeedScreen extends StatelessWidget {
  const PublicFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.read<ComplaintService>();

    return Scaffold(
      appBar: AppBar(title: const Text('✨ Resolved Issues')),
      body: StreamBuilder<List<ComplaintModel>>(
        stream: service.publicFeed,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final complaints = snap.data ?? [];

          if (complaints.isEmpty) {
            return const Center(child: Text('No resolved complaints yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (_, i) {
              final c = complaints[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.imageAfterUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(c.imageAfterUrl!, height: 160, width: double.infinity, fit: BoxFit.cover),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('✅', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Text(c.category, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const Spacer(),
                              Text(c.ward, style: const TextStyle(color: AppTheme.textMed, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.resolvedAt != null
                                ? 'Cleaned on ${c.resolvedAt!.day}/${c.resolvedAt!.month}/${c.resolvedAt!.year}'
                                : 'Recently resolved',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMed),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
