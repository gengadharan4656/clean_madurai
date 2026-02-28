import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home/home_screen.dart';
import '../waste_guidance/waste_guidance_screen.dart';

class SuccessScreen extends StatelessWidget {
  final String id;
  const SuccessScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F0),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .doc(id)
            .snapshots(),
        builder: (context, snap) {
          final d = snap.data?.data() as Map<String, dynamic>?;
          final wasteType = d?['aiWasteType'] ?? 'Analyzing...';
          final method = d?['recyclingMethod'] ?? 'Please wait...';
          final category = d?['category'] as String? ?? '';

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                        child: Text('✅',
                            style: TextStyle(fontSize: 50))),
                  ),
                  const SizedBox(height: 16),
                  const Text('Report Submitted!',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('ID: #$id',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B5E20))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('⭐ +10 Points Earned!',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.orange)),
                  ),
                  const SizedBox(height: 20),

                  // AI Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('🤖', style: TextStyle(fontSize: 22)),
                            SizedBox(width: 8),
                            Text('AI Waste Analysis',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _Row('🗂️ Waste Type', wasteType),
                        const Divider(height: 20),
                        _Row('♻️ How to Dispose', method),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Feature 3: Waste Guidance CTA
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WasteGuidanceScreen(
                          preselectedCategory: category,
                        ),
                      ),
                    ),
                    icon: const Text('♻️'),
                    label: const Text('View Full Segregation Guide'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1B5E20),
                      side: const BorderSide(color: Color(0xFF1B5E20)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Steps card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('What happens next?',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        _Step('1', 'Assigned to ward officer'),
                        _Step('2', 'Sanitation worker dispatched'),
                        _Step('3', 'You get notified when resolved'),
                      ],
                    ),
                  ),

                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HomeScreen()),
                          (_) => false),
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

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
}

class _Step extends StatelessWidget {
  final String n, t;
  const _Step(this.n, this.t);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            CircleAvatar(
                radius: 10,
                backgroundColor: const Color(0xFF1B5E20),
                child: Text(n,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700))),
            const SizedBox(width: 8),
            Text(t, style: const TextStyle(fontSize: 13)),
          ],
        ),
      );
}
