import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme.dart';

/// Terminal screen shown after checkout, reflecting the server-reconciled status.
class ResultScreen extends StatelessWidget {
  final TransactionModel txn;
  const ResultScreen({super.key, required this.txn});

  @override
  Widget build(BuildContext context) {
    final success = txn.status == 'SUCCESS';
    final pending = txn.status == 'PENDING' || txn.status == 'INITIALIZED';
    final color = success ? AppTheme.accent : (pending ? Colors.orange : Colors.red);
    final icon = success ? Icons.check : (pending ? Icons.hourglass_bottom : Icons.close);
    final title = success ? 'Payment successful' : (pending ? 'Payment pending' : 'Payment failed');

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 56),
                ),
                const SizedBox(height: 20),
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(formatAmount(txn.amount, txn.currency),
                    style: const TextStyle(fontSize: 18, color: Colors.black54)),
                if (pending) ...[
                  const SizedBox(height: 12),
                  const Text('We’ll confirm once your provider settles this payment.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                ],
                const SizedBox(height: 8),
                Text('Ref: ${txn.reference}',
                    style: const TextStyle(color: Colors.black38, fontSize: 12)),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
