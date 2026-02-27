// lib/screens/auth/otp_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import '../../main.dart';
import '../../services/auth_service.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;
  const OTPScreen({super.key, required this.phoneNumber});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otpController = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _selectedWard = 'Ward 1';
  bool _showProfile = false;

  final List<String> _wards = List.generate(40, (i) => 'Ward ${i + 1}');

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: AppTheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'OTP sent to\n${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppTheme.textMed),
            ),
            const SizedBox(height: 32),

            Pinput(
              controller: _otpController,
              length: 6,
              defaultPinTheme: PinTheme(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              focusedPinTheme: PinTheme(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primary, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 32),

            if (_showProfile) ...[
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  hintText: 'Enter your full name',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedWard,
                decoration: const InputDecoration(labelText: 'Your Ward'),
                items: _wards.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                onChanged: (v) => setState(() => _selectedWard = v!),
              ),
              const SizedBox(height: 24),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : () async {
                  if (_otpController.text.length < 6) return;

                  if (!_showProfile) {
                    setState(() => _showProfile = true);
                    return;
                  }

                  final success = await auth.verifyOTP(
                    otp: _otpController.text,
                    name: _nameCtrl.text.isEmpty ? 'Citizen' : _nameCtrl.text,
                    ward: _selectedWard,
                  );

                  if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid OTP. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: auth.isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text(_showProfile ? 'Verify & Create Account' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
