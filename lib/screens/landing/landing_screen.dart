// lib/screens/landing/landing_screen.dart
// NEW FILE – Pre-login scrollable landing page
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🧹', style: TextStyle(fontSize: 42)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Clean Madurai',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'AI-Powered Cleanliness Platform',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '🏙️ Madurai, Tamil Nadu',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Making our city cleaner, together',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Report issues, track resolutions, earn rewards.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Auth buttons at top
                  _AuthButtons(),
                  const SizedBox(height: 28),
                  const Text(
                    'App Features',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _FeatureCard(
                  emoji: '📸',
                  title: 'Report Garbage with Photo & Location',
                  description:
                      'Snap a photo of any garbage problem and instantly report it with your GPS location. Each complaint is auto-prioritised by category.',
                  color: const Color(0xFFE8F5E9),
                  borderColor: const Color(0xFF66BB6A),
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  emoji: '🚛',
                  title: 'Automatic Collector Notifications',
                  description:
                      'n8n automation sends instant alerts and daily morning summaries to garbage collectors in your ward — no manual follow-up needed.',
                  color: const Color(0xFFE3F2FD),
                  borderColor: const Color(0xFF42A5F5),
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  emoji: '📊',
                  title: 'Dashboard & Analytics',
                  description:
                      'Live statistics on complaint counts, resolution rates, ward cleanliness scores and top contributors — visible to all citizens.',
                  color: const Color(0xFFFFF8E1),
                  borderColor: const Color(0xFFFFCA28),
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  emoji: '🗺️',
                  title: 'Clean Route Suggestions',
                  description:
                      'Garbage collectors get an optimised daily cleanup route — sorted by priority, complaint age, and proximity. No maps API needed.',
                  color: const Color(0xFFF3E5F5),
                  borderColor: const Color(0xFFAB47BC),
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  emoji: '♻️',
                  title: 'Waste Segregation Guidance',
                  description:
                      'After every complaint you get instant guidance: which bin to use, whether it\'s recyclable, hazardous, or biodegradable.',
                  color: const Color(0xFFE0F7FA),
                  borderColor: const Color(0xFF26C6DA),
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  emoji: '🏆',
                  title: 'Points & Rewards System',
                  description:
                      'Earn points for every complaint submitted and resolved. Climb the leaderboard and become a Clean Madurai Champion.',
                  color: const Color(0xFFFFEBEE),
                  borderColor: const Color(0xFFEF5350),
                ),
                const SizedBox(height: 28),
                // Stats banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '🌟 Join Clean Madurai',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem('40', 'Wards'),
                          _StatItem('✓', 'PWA Ready'),
                          _StatItem('24/7', 'Monitoring'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _AuthButtons(),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Login',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1B5E20),
              side: const BorderSide(color: Color(0xFF1B5E20), width: 2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Register',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final Color color;
  final Color borderColor;

  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade700,
                    height: 1.4,
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

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
