import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// LoginScreen — Simple guest bypass for demo; replace with Firebase Auth in prod
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                // Logo
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🌿', style: TextStyle(fontSize: 44)),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'CleanMadurai',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Smart Waste Management\nfor a Cleaner Madurai',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                // Feature pills
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPill('📸 Report Garbage'),
                    _buildPill('🗑️ Find Dustbins'),
                    _buildPill('📊 Analytics'),
                    _buildPill('🏆 Leaderboard'),
                    _buildPill('⭐ Earn Points'),
                    _buildPill('🤖 AI Analysis'),
                  ],
                ),
                const SizedBox(height: 40),
                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: _isLoading
                      ? Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _continueAsGuest,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Continue as Citizen'),
                        ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _continueAsGuest,
                  child: const Text(
                    'Sign in as Collector',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
    );
  }
}
