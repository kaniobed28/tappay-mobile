import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';
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
      if (!mounted) return;
      await navigator.push(MaterialPageRoute(builder: (_) => CheckoutScreen(url: result.authorizationUrl!)));
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
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.l),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: AppColors.brand, size: 32),
                  ),
                  const SizedBox(height: 14),
                  const Text('Paying', style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(s.merchantName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.3)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  _row('Amount', trailing: AmountDisplay(amount: s.amount, currency: s.currency, size: 24)),
                  const Divider(height: 1),
                  _row('Currency', value: s.currency),
                  if (s.description != null && s.description!.isNotEmpty) ...[
                    const Divider(height: 1),
                    _row('Note', value: s.description!),
                  ],
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Row(children: [
                const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
                const SizedBox(width: 6),
                Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
              ]),
            ],
            const SizedBox(height: 28),
            GradientButton(
              label: 'Pay ${formatAmount(s.amount, s.currency)}',
              icon: Icons.lock_rounded,
              loading: _busy,
              onPressed: _confirm,
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_rounded, size: 14, color: AppColors.inkFaint),
                SizedBox(width: 6),
                Text('Secured by your payment provider', style: TextStyle(color: AppColors.inkFaint, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, {String? value, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.inkSoft)),
          trailing ?? Text(value ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
        ],
      ),
    );
  }
}
