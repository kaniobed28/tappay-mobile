import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/receipt_pdf_service.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// Digital receipt for a transaction, with a merchant-only refund action.
class ReceiptScreen extends StatefulWidget {
  final TransactionModel txn;
  const ReceiptScreen({super.key, required this.txn});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  late TransactionModel _txn;
  bool _refreshing = false;
  bool _refunding = false;
  bool _sharing = false;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _txn = widget.txn;
    _loadMe();
  }

  Future<void> _loadMe() async {
    try {
      final me = await context.read<ApiClient>().me();
      if (mounted) setState(() => _myUserId = me['id'] as String?);
    } catch (_) {}
  }

  bool get _canRefund => _txn.status == 'SUCCESS' && _myUserId != null && _myUserId == _txn.payeeId;

  /// A receipt PDF only makes sense for a settled transaction.
  bool get _canShare => _txn.status == 'SUCCESS' || _txn.status == 'REFUNDED';

  Future<void> _share() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sharing = true);
    try {
      await const ReceiptPdfService().shareReceipt(context, _txn);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Couldn’t create receipt: ${apiErrorMessage(e)}')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      final updated = await context.read<ApiClient>().getTransaction(_txn.id);
      if (mounted) setState(() => _txn = updated);
    } catch (_) {}
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _refund() async {
    final api = context.read<ApiClient>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Refund this payment?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 8),
            Text('${formatAmount(_txn.amount, _txn.currency)} will be returned to the customer. This can’t be undone.',
                style: const TextStyle(color: AppColors.inkSoft, height: 1.4)),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Refund ${formatAmount(_txn.amount, _txn.currency)}',
              gradient: const LinearGradient(colors: [Color(0xFFEF4457), Color(0xFFD1233A)]),
              glow: false,
              onPressed: () => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    setState(() => _refunding = true);
    try {
      final updated = await api.refund(_txn.id);
      if (mounted) setState(() => _txn = updated);
      messenger.showSnackBar(const SnackBar(content: Text('Refund issued')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _refunding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final success = _txn.status == 'SUCCESS';
    final pending = _txn.status == 'PENDING' || _txn.status == 'INITIALIZED';
    final color = success ? AppColors.success : (pending ? AppColors.warning : (_txn.status == 'REFUNDED' ? AppColors.inkSoft : AppColors.danger));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        actions: [
          IconButton(
            onPressed: _refreshing ? null : _refresh,
            icon: _refreshing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          children: [
            AppCard(
              padding: const EdgeInsets.all(24),
              shadow: AppShadows.raised,
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(success ? Icons.check_rounded : (pending ? Icons.hourglass_bottom_rounded : (_txn.status == 'REFUNDED' ? Icons.undo_rounded : Icons.close_rounded)), color: color, size: 30),
                  ),
                  const SizedBox(height: 16),
                  AmountDisplay(amount: _txn.amount, currency: _txn.currency, size: 36),
                  const SizedBox(height: 10),
                  StatusPill(status: _txn.status),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  _row('Reference', _txn.reference),
                  _row('Date', DateFormat.yMMMMd().add_jm().format(_txn.createdAt)),
                  if (_txn.description?.isNotEmpty == true) _row('Note', _txn.description!),
                  _row('Currency', _txn.currency),
                ],
              ),
            ),
            if (_canShare) ...[
              const SizedBox(height: 16),
              GradientButton(
                label: 'Share receipt',
                icon: Icons.ios_share_rounded,
                loading: _sharing,
                onPressed: _sharing ? null : _share,
              ),
            ],
            if (_canRefund) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _refunding ? null : _refund,
                  icon: _refunding
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger))
                      : const Icon(Icons.undo_rounded, color: AppColors.danger),
                  label: const Text('Refund this payment', style: TextStyle(color: AppColors.danger)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger), minimumSize: const Size.fromHeight(52)),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_rounded, size: 14, color: AppColors.inkFaint),
                SizedBox(width: 6),
                Text('Verified with the payment provider', style: TextStyle(color: AppColors.inkFaint, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(label, style: const TextStyle(color: AppColors.inkSoft))),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink))),
        ],
      ),
    );
  }
}
