import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';
import '../receipt/receipt_screen.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Text('Activity', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.5)),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.brand,
            onRefresh: _refresh,
            child: FutureBuilder<List<TransactionModel>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const _ListSkeleton();
                }
                if (snap.hasError) {
                  return _scroll(EmptyState(icon: Icons.wifi_off_rounded, title: 'Couldn’t load activity', subtitle: apiErrorMessage(snap.error!)));
                }
                final txns = snap.data ?? [];
                if (txns.isEmpty) {
                  return _scroll(const EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No transactions yet',
                    subtitle: 'Your payments and requests will show up here.',
                  ));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: txns.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _TxnTile(txn: txns[i]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _scroll(Widget child) => ListView(children: [const SizedBox(height: 80), child]);
}

class _TxnTile extends StatelessWidget {
  final TransactionModel txn;
  const _TxnTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final refunded = txn.status == 'REFUNDED';
    final failed = txn.status == 'FAILED';
    final tint = refunded ? AppColors.inkSoft : (failed ? AppColors.danger : AppColors.brand);
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptScreen(txn: txn))),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: tint.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(refunded ? Icons.undo_rounded : Icons.swap_horiz_rounded, color: tint, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.description?.isNotEmpty == true ? txn.description! : 'Payment',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 3),
                Text(DateFormat.MMMd().add_jm().format(txn.createdAt),
                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatAmount(txn.amount, txn.currency),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: failed ? AppColors.inkFaint : AppColors.ink,
                    decoration: (failed || refunded) ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.inkFaint,
                  )),
              const SizedBox(height: 5),
              StatusPill(status: txn.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        height: 72,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.l), border: Border.all(color: AppColors.border)),
      ),
    );
  }
}
