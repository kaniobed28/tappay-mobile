import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';
import 'requests_screen.dart';

/// Create a targeted money request: pick a recipient (email/phone), an amount and a note.
/// On success we route into the Requests inbox (Outgoing tab) so the sender can track it.
class RequestMoneyScreen extends StatefulWidget {
  const RequestMoneyScreen({super.key});

  @override
  State<RequestMoneyScreen> createState() => _RequestMoneyScreenState();
}

class _RequestMoneyScreenState extends State<RequestMoneyScreen> {
  final _target = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _target.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _minor => ((double.tryParse(_amount.text.trim()) ?? 0) * 100).round();

  Future<void> _submit() async {
    final target = _target.text.trim();
    if (target.isEmpty) {
      setState(() => _error = 'Enter the recipient’s email or phone');
      return;
    }
    if (_minor <= 0) {
      setState(() => _error = 'Enter an amount');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final api = context.read<ApiClient>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await api.createRequest(target: target, amount: _minor, note: _note.text.trim());
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Request sent')));
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const RequestsScreen(initialTab: 1)),
      );
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request money')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(gradient: AppGradients.brand, borderRadius: BorderRadius.circular(AppRadius.m)),
              child: const Icon(Icons.request_page_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 18),
            const Text('Ask to get paid',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.4)),
            const SizedBox(height: 4),
            const Text('We’ll notify them to pay you. They settle it right inside TapPay.',
                style: TextStyle(color: AppColors.inkSoft, height: 1.4)),
            const SizedBox(height: 22),
            TextField(
              controller: _target,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Recipient email or phone',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.payments_outlined),
                prefixText: 'GHS ',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Row(children: [
                const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
                const SizedBox(width: 6),
                Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
              ]),
            ],
            const SizedBox(height: 26),
            GradientButton(
              label: 'Send request',
              icon: Icons.send_rounded,
              loading: _busy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
