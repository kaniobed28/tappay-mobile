import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme.dart';

/// Digital receipt for a transaction. Refresh re-reconciles pending payments
/// against the provider so the status shown is always authoritative.
class ReceiptScreen extends StatefulWidget {
  final TransactionModel txn;
  const ReceiptScreen({super.key, required this.txn});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  late TransactionModel _txn;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _txn = widget.txn;
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      final updated = await context.read<ApiClient>().getTransaction(_txn.id);
      if (mounted) setState(() => _txn = updated);
    } catch (_) {/* keep showing what we have */}
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final success = _txn.status == 'SUCCESS';
    final pending = _txn.status == 'PENDING' || _txn.status == 'INITIALIZED';
    final statusColor = success ? AppTheme.accent : (pending ? Colors.orange : Colors.red);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        actions: [
          IconButton(
            onPressed: _refreshing ? null : _refresh,
            icon: _refreshing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            tooltip: 'Refresh status',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: statusColor.withValues(alpha: 0.12),
                      child: Icon(
                        success ? Icons.check : (pending ? Icons.hourglass_bottom : Icons.close),
                        color: statusColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      formatAmount(_txn.amount, _txn.currency),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _txn.status,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),
                    _row('Reference', _txn.reference),
                    _row('Date', DateFormat.yMMMMd().add_jm().format(_txn.createdAt)),
                    if (_txn.description?.isNotEmpty == true) _row('Note', _txn.description!),
                    _row('Currency', _txn.currency),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verified server-side with the payment provider.',
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
