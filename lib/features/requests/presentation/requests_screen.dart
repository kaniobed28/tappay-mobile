import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tappay/features/requests/data/request_models.dart';
import 'package:tappay/core/network/api_error.dart';
import 'package:tappay/features/payments/data/payments_api.dart';
import 'package:tappay/features/requests/data/requests_api.dart';
import 'package:tappay/core/realtime/realtime_service.dart';
import 'package:tappay/core/theme/app_theme.dart';
import 'package:tappay/core/widgets/ui.dart';
import 'package:tappay/features/payments/presentation/checkout_flow.dart';
import 'package:tappay/features/payments/presentation/result_screen.dart';

/// Tabbed inbox for money requests: things I've been asked to pay (Incoming) and
/// requests I've sent (Outgoing). Refreshes live off realtime request events.
class RequestsScreen extends StatefulWidget {
  final int initialTab;
  const RequestsScreen({super.key, this.initialTab = 0});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  StreamSubscription<RequestEvent>? _sub;

  late Future<List<PaymentRequestModel>> _incoming;
  late Future<List<PaymentRequestModel>> _outgoing;

  @override
  void initState() {
    super.initState();
    _incoming = context.read<RequestsApi>().incomingRequests();
    _outgoing = context.read<RequestsApi>().outgoingRequests();
    // Any request event (received / paid / declined / cancelled) may change both lists.
    _sub = context.read<RealtimeService>().requestEvents.listen((_) => _refreshAll());
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  void _refreshAll() {
    if (!mounted) return;
    setState(() {
      _incoming = context.read<RequestsApi>().incomingRequests();
      _outgoing = context.read<RequestsApi>().outgoingRequests();
    });
  }

  Future<void> _refreshIncoming() async {
    final f = context.read<RequestsApi>().incomingRequests();
    setState(() => _incoming = f);
    await f;
  }

  Future<void> _refreshOutgoing() async {
    final f = context.read<RequestsApi>().outgoingRequests();
    setState(() => _outgoing = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.brand,
          unselectedLabelColor: AppColors.inkSoft,
          indicatorColor: AppColors.brand,
          tabs: const [Tab(text: 'Incoming'), Tab(text: 'Outgoing')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _RequestList(
            future: _incoming,
            onRefresh: _refreshIncoming,
            incoming: true,
            emptyTitle: 'No requests to pay',
            emptySubtitle: 'When someone asks you to pay, it shows up here.',
            onChanged: _refreshAll,
          ),
          _RequestList(
            future: _outgoing,
            onRefresh: _refreshOutgoing,
            incoming: false,
            emptyTitle: 'No requests sent',
            emptySubtitle: 'Ask someone to pay you from the home screen.',
            onChanged: _refreshAll,
          ),
        ],
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  final Future<List<PaymentRequestModel>> future;
  final Future<void> Function() onRefresh;
  final bool incoming;
  final String emptyTitle;
  final String emptySubtitle;
  final VoidCallback onChanged;

  const _RequestList({
    required this.future,
    required this.onRefresh,
    required this.incoming,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: onRefresh,
      child: FutureBuilder<List<PaymentRequestModel>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _scroll(EmptyState(icon: Icons.wifi_off_rounded, title: 'Couldn’t load', subtitle: apiErrorMessage(snap.error!)));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return _scroll(EmptyState(icon: Icons.inbox_rounded, title: emptyTitle, subtitle: emptySubtitle));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _RequestCard(request: items[i], incoming: incoming, onChanged: onChanged),
          );
        },
      ),
    );
  }

  Widget _scroll(Widget child) => ListView(children: [const SizedBox(height: 100), child]);
}

class _RequestCard extends StatefulWidget {
  final PaymentRequestModel request;
  final bool incoming;
  final VoidCallback onChanged;
  const _RequestCard({required this.request, required this.incoming, required this.onChanged});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _busy = false;

  PaymentRequestModel get _r => widget.request;

  String get _counterparty => widget.incoming
      ? (_r.requester?.label ?? 'Someone')
      : (_r.payer?.label ?? 'Someone');

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() => _run(() async {
        await context.read<RequestsApi>().declineRequest(_r.id);
        widget.onChanged();
      });

  Future<void> _cancel() => _run(() async {
        await context.read<RequestsApi>().cancelRequest(_r.id);
        widget.onChanged();
      });

  Future<void> _pay() async {
    setState(() => _busy = true);
    final api = context.read<RequestsApi>();
    final payments = context.read<PaymentsApi>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await startPayment(context, () => api.payRequest(_r.id));
      if (!mounted || result == null) return;
      // Card checkout opens a page; mobile money waits for the prompt on the phone.
      final txn = await runCheckout(navigator, payments, result);
      if (!mounted || txn == null) return;
      widget.onChanged();
      await navigator.push(MaterialPageRoute(builder: (_) => ResultScreen(txn: txn)));
    } catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.incoming ? Icons.call_received_rounded : Icons.call_made_rounded,
                  color: AppColors.brand,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.incoming ? '$_counterparty is requesting' : 'Request to $_counterparty',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(DateFormat.MMMd().add_jm().format(r.createdAt),
                        style: const TextStyle(color: AppColors.inkFaint, fontSize: 11.5)),
                  ],
                ),
              ),
              _RequestStatusChip(status: r.status),
            ],
          ),
          const SizedBox(height: 14),
          AmountDisplay(amount: r.amount, currency: r.currency, size: 26),
          if (r.note != null && r.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(r.note!, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
          ],
          if (r.isPending && widget.incoming) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _decline,
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    label: 'Pay',
                    icon: Icons.lock_rounded,
                    loading: _busy,
                    onPressed: _pay,
                  ),
                ),
              ],
            ),
          ],
          if (r.isPending && !widget.incoming) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _busy ? null : _cancel,
              child: const Text('Cancel request'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Status pill covering the money-request lifecycle (StatusPill only maps txn states).
class _RequestStatusChip extends StatelessWidget {
  final String status;
  const _RequestStatusChip({required this.status});

  Color get _c => switch (status.toUpperCase()) {
        'PAID' => AppColors.success,
        'DECLINED' => AppColors.danger,
        'CANCELLED' => AppColors.inkSoft,
        _ => AppColors.warning, // PENDING
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.chip)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: _c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(status.toUpperCase(),
              style: TextStyle(color: _c, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}
