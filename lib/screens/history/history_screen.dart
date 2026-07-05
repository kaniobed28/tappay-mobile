import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<TransactionModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<TransactionModel>> _load() => context.read<ApiClient>().history();

  Future<void> _refresh() async {
    final f = _load();
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text('Activity', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<TransactionModel>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return ListView(children: [
                      const SizedBox(height: 120),
                      Center(child: Text(apiErrorMessage(snap.error!))),
                    ]);
                  }
                  final txns = snap.data ?? [];
                  if (txns.isEmpty) {
                    return ListView(children: const [
                      SizedBox(height: 120),
                      Icon(Icons.receipt_long_outlined, size: 48, color: Colors.black26),
                      SizedBox(height: 12),
                      Center(child: Text('No transactions yet', style: TextStyle(color: Colors.black54))),
                    ]);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: txns.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _TxnTile(txn: txns[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  final TransactionModel txn;
  const _TxnTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (txn.status) {
      'SUCCESS' => AppTheme.accent,
      'FAILED' => Colors.red,
      'REFUNDED' => Colors.grey,
      _ => Colors.orange,
    };
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          child: Icon(Icons.swap_horiz, color: statusColor),
        ),
        title: Text(txn.description?.isNotEmpty == true ? txn.description! : txn.reference,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${txn.status} · ${DateFormat.yMMMd().add_jm().format(txn.createdAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          formatAmount(txn.amount, txn.currency),
          style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
        ),
      ),
    );
  }
}
