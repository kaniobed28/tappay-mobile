import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// Two-step phone sign-in: enter number → enter the SMS code.
/// Functional once Firebase (Phone provider) is enabled; shows a clear message otherwise.
class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  String? _verificationId;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phone.text.trim();
    if (!phone.startsWith('+') || phone.length < 8) {
      setState(() => _error = 'Enter in international format, e.g. +233…');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    await context.read<AuthService>().startPhoneSignIn(
          phoneNumber: phone,
          codeSent: (id) {
            if (!mounted) return;
            setState(() {
              _verificationId = id;
              _busy = false;
            });
          },
          onError: (msg) {
            if (!mounted) return;
            setState(() {
              _error = msg;
              _busy = false;
            });
          },
        );
  }

  Future<void> _confirm() async {
    if (_code.text.trim().length < 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().confirmPhoneCode(_verificationId!, _code.text.trim());
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      setState(() => _error = 'Invalid code. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final codeStep = _verificationId != null;
    return Scaffold(
      appBar: AppBar(title: Text(codeStep ? 'Enter code' : 'Phone sign-in')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(gradient: AppGradients.brand, borderRadius: BorderRadius.circular(AppRadius.m)),
              child: Icon(codeStep ? Icons.sms_rounded : Icons.phone_iphone_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 18),
            Text(codeStep ? 'Verify your number' : 'What’s your number?',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.4)),
            const SizedBox(height: 4),
            Text(
              codeStep ? 'We sent a 6-digit code to ${_phone.text.trim()}.' : 'We’ll text you a code to confirm it’s you.',
              style: const TextStyle(color: AppColors.inkSoft, height: 1.4),
            ),
            const SizedBox(height: 22),
            if (!codeStep)
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number', hintText: '+233 20 000 0000', prefixIcon: Icon(Icons.phone_outlined)),
              )
            else
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 8),
                decoration: const InputDecoration(counterText: '', hintText: '••••••'),
              ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
                const SizedBox(width: 6),
                Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
              ]),
            ],
            const SizedBox(height: 22),
            GradientButton(
              label: codeStep ? 'Verify & continue' : 'Send code',
              icon: codeStep ? Icons.check_rounded : Icons.sms_rounded,
              loading: _busy,
              onPressed: codeStep ? _confirm : _sendCode,
            ),
            if (codeStep) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : () => setState(() => _verificationId = null),
                child: const Text('Change number'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
