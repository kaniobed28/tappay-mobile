import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/hce_service.dart';
import '../../services/realtime_service.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// The QR/NFC payload string. It carries only the session id — the customer resolves
/// and verifies the full signed session from the backend.
String sessionUri(String id) => 'tappay://s/$id';

class CollectScreen extends StatefulWidget {
  final SessionPayload session;
  const CollectScreen({super.key, required this.session});

  @override
  State<CollectScreen> createState() => _CollectScreenState();
}

class _CollectScreenState extends State<CollectScreen> {
  final HceService _hce = HceService();
  StreamSubscription<PaymentEvent>? _sub;
  Timer? _fallbackPoll;
  Timer? _ticker;
  bool _paid = false;
  bool _broadcasting = false;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = DateTime.parse(widget.session.expiresAt).difference(DateTime.now());
    _listenRealtime();
    _startFallbackPoll();
    _startTicker();
    _startNfcBroadcast();
  }

  Future<void> _startNfcBroadcast() async {
    if (!await _hce.isSupported()) return;
    final ok = await _hce.broadcast(sessionUri(widget.session.id));
    if (mounted) setState(() => _broadcasting = ok);
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final r = DateTime.parse(widget.session.expiresAt).difference(DateTime.now());
      if (mounted) setState(() => _remaining = r.isNegative ? Duration.zero : r);
    });
  }

  void _listenRealtime() {
    _sub = context.read<RealtimeService>().events.listen((event) {
      if (event.sessionId == widget.session.id && event.type == 'payment.success') {
        _onPaid();
      }
    });
  }

  void _startFallbackPoll() {
    _fallbackPoll = Timer.periodic(const Duration(seconds: 12), (_) async {
      if (_paid) return;
      try {
        final txns = await context.read<ApiClient>().history();
        if (txns.any((t) => t.sessionId == widget.session.id && t.isSuccess)) _onPaid();
      } catch (_) {}
    });
  }

  void _onPaid() {
    if (_paid) return;
    setState(() => _paid = true);
    _sub?.cancel();
    _fallbackPoll?.cancel();
    _ticker?.cancel();
    _hce.stop();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _fallbackPoll?.cancel();
    _ticker?.cancel();
    _hce.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_paid ? 'Paid' : 'Receiving')),
      body: AnimatedSwitcher(
        duration: AppMotion.base,
        child: _paid ? _paidView() : _collectView(),
      ),
    );
  }

  Widget _collectView() {
    final s = widget.session;
    final expired = _remaining == Duration.zero;
    return SingleChildScrollView(
      key: const ValueKey('collect'),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        children: [
          AmountDisplay(amount: s.amount, currency: s.currency, size: 44),
          if (s.description != null && s.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(s.description!, style: const TextStyle(color: AppColors.inkSoft)),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.raised,
            ),
            child: expired
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                    child: Column(children: [
                      Icon(Icons.timer_off_rounded, size: 40, color: AppColors.inkFaint),
                      SizedBox(height: 12),
                      Text('This code expired', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                      SizedBox(height: 4),
                      Text('Go back and start a new request.', style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                    ]),
                  )
                : Column(
                    children: [
                      QrImageView(
                        data: sessionUri(s.id),
                        version: QrVersions.auto,
                        size: 220,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.ink),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.ink),
                      ),
                      const SizedBox(height: 14),
                      const Text('Ask the customer to scan', style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          if (!expired) _CountdownBar(remaining: _remaining, total: 180),
          if (_broadcasting && !expired) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppRadius.m),
                border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const _PulseDot(),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('NFC ready — customer can tap this phone',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink, fontSize: 13.5)),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 28),
          const WaitingIndicator(label: 'Waiting for payment…'),
        ],
      ),
    );
  }

  Widget _paidView() {
    return Center(
      key: const ValueKey('paid'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SuccessCheck(size: 104),
            const SizedBox(height: 28),
            const Text('Payment received', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.4)),
            const SizedBox(height: 8),
            AmountDisplay(amount: widget.session.amount, currency: widget.session.currency, size: 30, color: AppColors.success),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: 'Done',
                gradient: AppGradients.mint,
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownBar extends StatelessWidget {
  final Duration remaining;
  final int total;
  const _CountdownBar({required this.remaining, required this.total});

  @override
  Widget build(BuildContext context) {
    final frac = (remaining.inSeconds / total).clamp(0.0, 1.0);
    final low = remaining.inSeconds < 30;
    final mm = remaining.inMinutes;
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule_rounded, size: 14, color: low ? AppColors.danger : AppColors.inkSoft),
            const SizedBox(width: 6),
            Text('Expires in $mm:$ss',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: low ? AppColors.danger : AppColors.inkSoft)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 5,
            backgroundColor: AppColors.surfaceAlt,
            valueColor: AlwaysStoppedAnimation(low ? AppColors.danger : AppColors.brand),
          ),
        ),
      ],
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        return SizedBox(
          width: 14,
          height: 14,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 14 * (0.5 + _c.value),
              height: 14 * (0.5 + _c.value),
              decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: (1 - _c.value) * 0.4), shape: BoxShape.circle),
            ),
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle)),
          ]),
        );
      },
    );
  }
}
