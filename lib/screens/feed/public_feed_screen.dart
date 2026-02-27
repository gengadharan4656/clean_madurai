import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/complaint_service.dart';

class PublicFeedScreen extends StatelessWidget {
  const PublicFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.read<ComplaintService>();
    return Scaffold(
      appBar: AppBar(title: const Text('✨ Resolved Issues'),
          automaticallyImplyLeading: false),
      body: StreamBuilder<List<ComplaintModel>>(
        stream: svc.publicFeed,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(
                child: Text('No resolved complaints yet.',
                    style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final c = list[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.imageBeforeUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14)),
                        child: Image.network(c.imageBeforeUrl,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Text('✅',
                              style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(c.category,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Text(c.ward,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
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
