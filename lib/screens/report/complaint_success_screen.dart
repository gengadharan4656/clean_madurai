// lib/screens/report/complaint_success_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../home/home_screen.dart';

class ComplaintSuccessScreen extends StatelessWidget {
  final String complaintId;
  const ComplaintSuccessScreen({super.key, required this.complaintId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .doc(complaintId)
            .snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data() as Map<String, dynamic>?;
          final aiWasteType = data?['aiWasteType'] ?? 'Analyzing...';
          final recyclingMethod = data?['recyclingMethod'] ?? 'Please wait...';
          final aiDescription = data?['aiDescription'] ?? '';

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // Success Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('✅', style: TextStyle(fontSize: 52)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Report Submitted!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Complaint ID: ', style: TextStyle(color: AppTheme.textMed)),
                      Text(
                        '#$complaintId',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 18),
                        SizedBox(width: 4),
                        Text('+10 Points Earned!', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.orange)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // AI Analysis Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('🤖', style: TextStyle(fontSize: 24)),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'AI Waste Analysis',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _AiRow(label: '🗂️ Waste Type', value: aiWasteType),
                        const Divider(height: 20),
                        _AiRow(label: '♻️ How to Dispose', value: recyclingMethod),
                        if (aiDescription.isNotEmpty) ...[
                          const Divider(height: 20),
                          _AiRow(label: '💡 Info', value: aiDescription),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // What happens next
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('What happens next?', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        _Step('1', 'Your report is assigned to a ward officer'),
                        _Step('2', 'A sanitation worker is dispatched'),
                        _Step('3', 'You\'ll be notified when resolved'),
                        _Step('4', 'Earn points when complaint resolves!'),
                      ],
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (_) => false,
                      ),
                      child: const Text('Back to Home'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AiRow extends StatelessWidget {
  final String label, value;
  const _AiRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMed, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String num, text;
  const _Step(this.num, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
