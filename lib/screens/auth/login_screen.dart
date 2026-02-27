import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _usePhone = true;
  String _role = 'citizen';
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _phoneLogin(AuthService auth) async {
    if (_role == 'collector') {
      _snack('Collectors must use Email login for secure access.');
      return;
    }
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      _snack('Enter valid 10-digit phone number');
      return;
    }
    await auth.sendOTP(
      phoneNumber: '+91$phone',
      onCodeSent: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OTPScreen(phoneNumber: '+91$phone')),
      ),
      onError: (e) => _snack(e),
    );
  }

  Future<void> _emailLogin(AuthService auth) async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _snack('Enter email and password');
      return;
    }
    final ok = await auth.signInWithEmail(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      expectedRole: _role,
    );
    if (!ok && mounted) _snack(auth.error ?? 'Login failed');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(child: Text('🧹', style: TextStyle(fontSize: 36))),
                  ),
                  const SizedBox(height: 14),
                  const Text('Clean Madurai',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    _role == 'collector'
                        ? 'Collector login & field operations'
                        : 'Citizen reports for a cleaner city',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sign In', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            _RoleToggle(
                              label: '👤 Citizen',
                              selected: _role == 'citizen',
                              onTap: () => setState(() => _role = 'citizen'),
                            ),
                            _RoleToggle(
                              label: '🚛 Collector',
                              selected: _role == 'collector',
                              onTap: () => setState(() => _role = 'collector'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            _Tab('📱 Phone', _usePhone, () => setState(() => _usePhone = true)),
                            _Tab('✉️ Email', !_usePhone, () => setState(() => _usePhone = false)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_usePhone) ...[
                        const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: const InputDecoration(prefixText: '+91  ', hintText: '9876543210', counterText: ''),
                        ),
                        const SizedBox(height: 6),
                        const Text('Phone OTP is available for Citizen mode.', style: TextStyle(fontSize: 11, color: Colors.black54)),
                        const SizedBox(height: 20),
                        _BigBtn(label: 'Send OTP', loading: auth.isLoading, onTap: () => _phoneLogin(auth)),
                      ] else ...[
                        const Text('Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(hintText: 'your@email.com'),
                        ),
                        const SizedBox(height: 14),
                        const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _BigBtn(label: _role == 'collector' ? 'Collector Sign In' : 'Sign In', loading: auth.isLoading, onTap: () => _emailLogin(auth)),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            ),
                            child: const Text("Don't have an account? Register"),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleToggle({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1B5E20) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: selected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1B5E20) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              )),
        ),
      ),
    );
  }
}

class _BigBtn extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _BigBtn({required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
