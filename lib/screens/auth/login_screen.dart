import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _register = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    try {
      if (_register) {
        await auth.register(_email.text, _password.text);
      } else {
        await auth.signIn(_email.text, _password.text);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      body: Stack(
        children: [
          // Brand backdrop
          Container(
            height: MediaQuery.of(context).size.height * 0.42,
            decoration: const BoxDecoration(gradient: AppGradients.brand),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _DotGrid()),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Center(child: BrandMark(size: 68)),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text('TapPay',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text('Pay with a tap.',
                        style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 40),
                  AppCard(
                    padding: const EdgeInsets.all(22),
                    shadow: AppShadows.raised,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(_register ? 'Create your account' : 'Welcome back',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(_register ? 'A few seconds to get started.' : 'Sign in to continue.',
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 20),
                          if (!auth.firebaseReady)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.s),
                                border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text('Demo mode — any email & password signs you in.',
                                        style: TextStyle(fontSize: 12, color: AppColors.ink)),
                                  ),
                                ],
                              ),
                            ),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
                            validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline_rounded)),
                            validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Row(children: [
                              const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
                              const SizedBox(width: 6),
                              Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                            ]),
                          ],
                          const SizedBox(height: 22),
                          GradientButton(
                            label: _register ? 'Create account' : 'Sign in',
                            icon: _register ? Icons.person_add_alt_1_rounded : Icons.login_rounded,
                            loading: _busy,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _busy ? null : () => setState(() => _register = !_register),
                      child: Text.rich(TextSpan(
                        text: _register ? 'Already have an account? ' : "New to TapPay? ",
                        style: const TextStyle(color: AppColors.inkSoft),
                        children: [
                          TextSpan(
                            text: _register ? 'Sign in' : 'Create one',
                            style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700),
                          ),
                        ],
                      )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle dotted texture over the brand header.
class _DotGrid extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.06);
    const gap = 26.0;
    for (double y = 20; y < size.height * 0.4; y += gap) {
      for (double x = 20; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
