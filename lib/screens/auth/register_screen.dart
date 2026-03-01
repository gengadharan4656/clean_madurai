// lib/screens/auth/register_screen.dart
// UPDATED: Tamil/English toggle + localized strings (no other working logic changed)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_lang.dart';
import '../../i18n/strings.dart';

import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _workerIdCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();

  String _ward = 'Ward 1';
  String _role = 'citizen';
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _workerIdCtrl.dispose();
    _aadhaarCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context, 'createAccount')),
        actions: [
          TextButton(
            onPressed: () => context.read<AppLang>().toggle(),
            child: Text(
              S.of(context, 'langBtn'), // தமிழ் / EN
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _RoleTab(
                    icon: Icons.person,
                    label: S.of(context, 'role_citizen_plain'),
                    selected: _role == 'citizen',
                    onTap: () => setState(() => _role = 'citizen'),
                  ),
                  _RoleTab(
                    icon: Icons.local_shipping,
                    label: S.of(context, 'role_collector_plain'),
                    selected: _role == 'collector',
                    onTap: () => setState(() => _role = 'collector'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _field(S.of(context, 'fullName'), _nameCtrl, hint: S.of(context, 'fullName_hint')),
            const SizedBox(height: 14),

            _field(
              S.of(context, 'email'),
              _emailCtrl,
              hint: S.of(context, 'email_hint'),
              type: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),

            _field(
              S.of(context, 'password'),
              _passCtrl,
              hint: S.of(context, 'password_hint_register'),
              obscure: _obscure,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              ),
            ),
            const SizedBox(height: 14),

            Text(
              S.of(context, 'yourWard'),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _ward,
              decoration: const InputDecoration(),
              items: List.generate(40, (i) => 'Ward ${i + 1}')
                  .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                  .toList(),
              onChanged: (v) => setState(() => _ward = v!),
            ),

            if (_role == 'collector') ...[
              const SizedBox(height: 18),
              Text(
                S.of(context, 'collectorDetails'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),

              _field(S.of(context, 'workerId'), _workerIdCtrl, hint: S.of(context, 'workerId_hint')),
              const SizedBox(height: 14),

              _field(
                S.of(context, 'aadhaarNumber'),
                _aadhaarCtrl,
                hint: S.of(context, 'aadhaar_hint'),
                type: TextInputType.number,
              ),
              const SizedBox(height: 14),

              _field(S.of(context, 'vehicleNumber'), _vehicleCtrl, hint: S.of(context, 'vehicle_hint')),
            ],

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _submit,
                child: auth.isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text(
                  _role == 'collector'
                      ? S.of(context, 'createCollectorAccount')
                      : S.of(context, 'createCitizenAccount'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final auth = context.read<AuthService>();

    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty) {
      _snack(S.of(context, 'reg_err_required'));
      return;
    }

    if (_role == 'collector') {
      if (_workerIdCtrl.text.trim().isEmpty ||
          _aadhaarCtrl.text.trim().length != 12 ||
          _vehicleCtrl.text.trim().isEmpty) {
        _snack(S.of(context, 'reg_err_collector_fields'));
        return;
      }
    }

    final ok = await auth.registerWithEmail(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      name: _nameCtrl.text.trim(),
      ward: _ward,
      role: _role,
      extraDetails: _role == 'collector'
          ? {
        'workerId': _workerIdCtrl.text.trim(),
        'aadhaarLast4': _aadhaarCtrl.text.trim().substring(8),
        'vehicleNumber': _vehicleCtrl.text.trim(),
      }
          : null,
    );

    if (!mounted) return;
    if (!ok) {
      _snack(auth.error ?? S.of(context, 'reg_err_failed'));
    } else {
      // ✅ close Register + Login and reveal AuthWrapper which will route to Home/Collector
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _field(
      String label,
      TextEditingController ctrl, {
        String? hint,
        TextInputType? type,
        bool obscure = false,
        Widget? suffix,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          obscureText: obscure,
          decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
        ),
      ],
    );
  }
}

class _RoleTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1B5E20) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.grey.shade700,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}