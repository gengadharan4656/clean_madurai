import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        title: const Text('Create Account'),
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
                    label: 'Citizen',
                    selected: _role == 'citizen',
                    onTap: () => setState(() => _role = 'citizen'),
                  ),
                  _RoleTab(
                    icon: Icons.local_shipping,
                    label: 'Garbage Collector',
                    selected: _role == 'collector',
                    onTap: () => setState(() => _role = 'collector'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _field('Full Name', _nameCtrl, hint: 'Your full name'),
            const SizedBox(height: 14),
            _field('Email', _emailCtrl,
                hint: 'your@email.com', type: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _field('Password', _passCtrl,
                hint: 'Min 6 characters',
                obscure: _obscure,
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                )),
            const SizedBox(height: 14),
            const Text('Your Ward',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey)),
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
              const Text('Collector Details',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _field('Worker ID', _workerIdCtrl, hint: 'Ex: MDU-GC-1076'),
              const SizedBox(height: 14),
              _field('Aadhaar Number', _aadhaarCtrl,
                  hint: '12 digits', type: TextInputType.number),
              const SizedBox(height: 14),
              _field('Vehicle Number', _vehicleCtrl,
                  hint: 'TN 58 AB 1234'),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _submit,
                child: auth.isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : Text(
                        _role == 'collector'
                            ? 'Create Collector Account'
                            : 'Create Citizen Account',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
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
      _snack('Fill all mandatory fields');
      return;
    }

    if (_role == 'collector') {
      if (_workerIdCtrl.text.trim().isEmpty ||
          _aadhaarCtrl.text.trim().length != 12 ||
          _vehicleCtrl.text.trim().isEmpty) {
        _snack('Collector needs Worker ID, 12-digit Aadhaar and Vehicle Number');
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
      _snack(auth.error ?? 'Registration failed');
    } else {
      Navigator.pop(context);
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
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey)),
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
