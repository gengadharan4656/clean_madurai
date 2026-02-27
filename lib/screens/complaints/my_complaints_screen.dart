// lib/screens/complaints/my_complaints_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/complaint_service.dart';
import '../../models/complaint_model.dart';

class MyComplaintsScreen extends StatelessWidget {
  const MyComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.read<ComplaintService>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: StreamBuilder<List<ComplaintModel>>(
        stream: service.myComplaints,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final complaints = snap.data ?? [];

          if (complaints.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📋', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 12),
                  const Text('No reports yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Submit your first report to help clean Madurai!',
                      style: TextStyle(color: AppTheme.textMed), textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (_, i) => _ComplaintCard(complaint: complaints[i]),
          );
        },
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  const _ComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(complaint.status);
    final priorityColor = _priorityColor(complaint.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    complaint.imageBeforeUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(complaint.category, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('#${complaint.id}', style: const TextStyle(fontSize: 12, color: AppTheme.textMed)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _Badge(complaint.status.replaceAll('_', ' '), statusColor),
                          const SizedBox(width: 6),
                          _Badge(complaint.priority, priorityColor),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(complaint.statusEmoji, style: const TextStyle(fontSize: 28)),
              ],
            ),
          ),

          // AI Result (if available)
          if (complaint.aiWasteType != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Text('🤖', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint.aiWasteType!,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          complaint.recyclingMethod ?? '',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMed),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Before/After (if resolved)
          if (complaint.isResolved && complaint.imageAfterUrl != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Before vs After', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(complaint.imageBeforeUrl, height: 80, fit: BoxFit.cover),
                            ),
                            const Text('Before', style: TextStyle(fontSize: 11, color: Colors.red)),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, color: Colors.green),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(complaint.imageAfterUrl!, height: 80, fit: BoxFit.cover),
                            ),
                            const Text('After', style: TextStyle(fontSize: 11, color: Colors.green)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Date
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  complaint.createdAt != null
                      ? '${complaint.createdAt!.day}/${complaint.createdAt!.month}/${complaint.createdAt!.year}'
                      : 'Just now',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (complaint.isResolved && complaint.resolvedAt != null) ...[
                  const SizedBox(width: 10),
                  Icon(Icons.check_circle, size: 14, color: Colors.green.shade400),
                  const SizedBox(width: 4),
                  Text(
                    'Resolved ${complaint.resolvedAt!.day}/${complaint.resolvedAt!.month}',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'submitted': return Colors.blue;
      case 'assigned': return Colors.purple;
      case 'in_progress': return Colors.orange;
      case 'resolved': return Colors.green;
      default: return Colors.grey;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.amber;
      default: return Colors.green;
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
