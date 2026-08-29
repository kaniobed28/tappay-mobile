import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tappay/core/theme/app_theme.dart';
import 'package:tappay/core/widgets/ui.dart';
import 'package:tappay/features/payments/data/payment_models.dart';
import 'package:tappay/features/payments/data/payments_api.dart';

/// Waiting room for a *push* payment (mobile money).
///
/// There is no checkout page to open: the provider has sent an approval prompt to the
/// payer's own handset, so the app polls the backend — which re-verifies with the
/// provider on every read — until the payment reaches a terminal state. Pops with the
/// settled [TransactionModel], or with `null` if the payer backs out while it is still
/// pending (the payment may still land; history and notifications will show it).
class AwaitingApprovalScreen extends StatefulWidget {
  final PaymentResult payment;
  const AwaitingApprovalScreen({super.key, required this.payment});

  @override
  State<AwaitingApprovalScreen> createState() => _AwaitingApprovalScreenState();
}

class _AwaitingApprovalScreenState extends State<AwaitingApprovalScreen> {
  static const _pollInterval = Duration(seconds: 3);
  static const _timeout = Duration(minutes: 3);

  Timer? _timer;
  DateTime _waitingSince = DateTime.now();
  bool _checking = false;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    _waitingSince = DateTime.now();
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (_checking || !mounted) return;
    if (DateTime.now().difference(_waitingSince) > _timeout) {
      _timer?.cancel();
      if (mounted) setState(() => _timedOut = true);
      return;
    }
    setState(() => _checking = true);
    try {
      final txn = await context.read<PaymentsApi>().getTransaction(widget.payment.transactionId);
      if (!mounted) return;
      // INITIALIZED/PENDING mean the payer hasn't approved yet — keep waiting.
      if (txn.status != 'PENDING' && txn.status != 'INITIALIZED') {
        _timer?.cancel();
        Navigator.of(context).pop(txn);
        return;
      }
    } catch (_) {
      // A failed poll is normal on a flaky connection; the next tick tries again.
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    return PopScope(
      // Leaving is allowed — the prompt lives on the payer's phone, not in this screen.
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Approve on your phone'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smartphone_rounded, size: 52, color: AppColors.brand),
                  ),
                ),
                const SizedBox(height: AppSpace.xxl),
                Center(child: AmountDisplay(amount: p.amount, currency: p.currency, size: 34)),
                const SizedBox(height: AppSpace.l),
                Text(
                  _timedOut
                      ? 'We haven’t seen this payment yet.'
                      : (p.instruction ??
                          'Approve the payment prompt on your phone to complete this payment.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkSoft, height: 1.5),
                ),
                const SizedBox(height: AppSpace.xxl),
                if (!_timedOut)
                  const WaitingIndicator(label: 'Waiting for approval…')
                else
                  Text(
                    'If you approved it, it may still be settling — check your history in a moment.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.inkFaint, fontSize: 13, height: 1.4),
                  ),
                const Spacer(),
                GradientButton(
                  label: _timedOut ? 'Check again' : 'I’ve approved it',
                  loading: _checking,
                  onPressed: () {
                    if (_timedOut) {
                      setState(() => _timedOut = false);
                      _startPolling();
                    }
                    _poll();
                  },
                ),
                const SizedBox(height: AppSpace.m),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
