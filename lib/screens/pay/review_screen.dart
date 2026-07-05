import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import 'checkout_screen.dart';
import 'result_screen.dart';

/// Customer reviews the resolved session before authorizing payment.
class ReviewScreen extends StatefulWidget {
  final SessionPayload session;
  const ReviewScreen({super.key, required this.session});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final api = context.read<ApiClient>();
    final navigator = Navigator.of(context);
    try {
      final PaymentResult result = await api.pay(widget.session.id);

      if (result.authorizationUrl == null) {
        setState(() => _error = 'Provider did not return a checkout URL');
        return;
      }

      // Open the provider checkout; it returns when the deep-link callback fires or the
      // user backs out. Either way we reconcile the transaction status server-side.
      if (!mounted) return;
      await navigator.push(MaterialPageRoute(
        builder: (_) => CheckoutScreen(url: result.authorizationUrl!),
      ));

      final txn = await api.getTransaction(result.transactionId);
      if (!mounted) return;
      navigator.pushReplacement(MaterialPageRoute(builder: (_) => ResultScreen(txn: txn)));
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: CircleAvatar(
                radius: 34,
                backgroundColor: AppTheme.brand.withValues(alpha: 0.1),
                child: const Icon(Icons.store, color: AppTheme.brand, size: 34),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(s.merchantName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _row('Amount', formatAmount(s.amount, s.currency), emphasize: true),
                    const Divider(height: 24),
                    _row('Currency', s.currency),
                    if (s.description != null && s.description!.isNotEmpty) ...[
                      const Divider(height: 24),
                      _row('Note', s.description!),
                    ],
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _busy ? null : _confirm,
              icon: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.lock_outline),
              label: Text('Pay ${formatAmount(s.amount, s.currency)}'),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Secured by your payment provider',
                  style: TextStyle(color: Colors.black45, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasize = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
              fontSize: emphasize ? 20 : 15,
            )),
      ],
    );
  }
}
