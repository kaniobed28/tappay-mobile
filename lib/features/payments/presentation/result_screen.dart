import 'package:flutter/material.dart';
import 'package:tappay/features/payments/data/payment_models.dart';
import 'package:tappay/core/theme/app_theme.dart';
import 'package:tappay/core/widgets/ui.dart';

/// Terminal screen after checkout, reflecting the server-reconciled status.
class ResultScreen extends StatelessWidget {
  final TransactionModel txn;
  const ResultScreen({super.key, required this.txn});

  @override
  Widget build(BuildContext context) {
    final success = txn.status == 'SUCCESS';
    final pending = txn.status == 'PENDING' || txn.status == 'INITIALIZED';
    final color = success ? AppColors.success : (pending ? AppColors.warning : AppColors.danger);
    final title = success ? 'Payment successful' : (pending ? 'Payment pending' : 'Payment failed');
    final sub = success
        ? 'Your payment went through.'
        : (pending ? 'We’ll confirm once your provider settles this.' : 'No money was taken. You can try again.');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              if (success)
                const SuccessCheck(size: 104)
              else
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 28, spreadRadius: 2),
                  ]),
                  child: Icon(pending ? Icons.hourglass_bottom_rounded : Icons.close_rounded, color: Colors.white, size: 56),
                ),
              const SizedBox(height: 28),
              Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.4)),
              const SizedBox(height: 8),
              Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft, height: 1.4)),
              const SizedBox(height: 24),
              AmountDisplay(amount: txn.amount, currency: txn.currency, size: 34, color: color),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(999)),
                child: Text('Ref ${txn.reference}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              GradientButton(
                label: 'Done',
                gradient: success ? AppGradients.mint : AppGradients.brand,
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
