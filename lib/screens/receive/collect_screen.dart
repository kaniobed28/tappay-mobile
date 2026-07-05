import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/nfc_service.dart';
import '../../services/realtime_service.dart';
import '../../theme.dart';

/// The QR/NFC payload string that travels between devices. It only carries the session
/// id — the customer resolves (and verifies) the full signed session from the backend.
String sessionUri(String id) => 'tappay://s/$id';

class CollectScreen extends StatefulWidget {
  final SessionPayload session;
  const CollectScreen({super.key, required this.session});

  @override
  State<CollectScreen> createState() => _CollectScreenState();
}

class _CollectScreenState extends State<CollectScreen> {
  StreamSubscription<PaymentEvent>? _sub;
  Timer? _fallbackPoll;
  Timer? _ticker;
  bool _paid = false;
  bool _nfcAvailable = false;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = DateTime.parse(widget.session.expiresAt).difference(DateTime.now());
    _listenRealtime();
    _startFallbackPoll();
    _startTicker();
    _checkNfc();
  }

  Future<void> _checkNfc() async {
    final ok = await context.read<NfcService>().isAvailable();
    if (mounted) setState(() => _nfcAvailable = ok);
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final r = DateTime.parse(widget.session.expiresAt).difference(DateTime.now());
      if (mounted) setState(() => _remaining = r.isNegative ? Duration.zero : r);
    });
  }

  /// Primary path: an instant push from the backend when this session is paid.
  void _listenRealtime() {
    _sub = context.read<RealtimeService>().events.listen((event) {
      if (event.sessionId == widget.session.id && event.type == 'payment.success') {
        _onPaid();
      }
    });
  }

  /// Safety net if the websocket is blocked on the network — reconciles slowly.
  void _startFallbackPoll() {
    _fallbackPoll = Timer.periodic(const Duration(seconds: 12), (_) async {
      if (_paid) return;
      try {
        final txns = await context.read<ApiClient>().history();
        if (txns.any((t) => t.sessionId == widget.session.id && t.isSuccess)) {
          _onPaid();
        }
      } catch (_) {/* keep trying */}
    });
  }

  void _onPaid() {
    if (_paid) return;
    setState(() => _paid = true);
    _sub?.cancel();
    _fallbackPoll?.cancel();
    _ticker?.cancel();
  }

  Future<void> _broadcastNfc() async {
    final nfc = context.read<NfcService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(const SnackBar(content: Text('Hold the customer device near…')));
      await nfc.writeSessionId(sessionUri(widget.session.id));
      messenger.showSnackBar(const SnackBar(content: Text('Sent over NFC')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('NFC failed: $e')));
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _fallbackPoll?.cancel();
    _ticker?.cancel();
    context.read<NfcService>().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return Scaffold(
      appBar: AppBar(title: const Text('Collecting payment')),
      body: _paid ? _paidView() : _collectView(s),
    );
  }

  Widget _collectView(SessionPayload s) {
    final expired = _remaining == Duration.zero;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(formatAmount(s.amount, s.currency),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
          if (s.description != null && s.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(s.description!, style: const TextStyle(color: Colors.black54)),
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8EAF0)),
            ),
            child: expired
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('Session expired.\nGo back and create a new one.',
                        textAlign: TextAlign.center),
                  )
                : QrImageView(
                    data: sessionUri(s.id),
                    version: QrVersions.auto,
                    size: 220,
                  ),
          ),
          const SizedBox(height: 16),
          Text('Ask the customer to scan this code',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          if (!expired)
            Text('Expires in ${_remaining.inMinutes}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          if (_nfcAvailable && !expired) ...[
            const Row(children: [
              Expanded(child: Divider()),
              Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or')),
              Expanded(child: Divider()),
            ]),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _broadcastNfc,
              icon: const Icon(Icons.contactless),
              label: const Text('Send via NFC'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ],
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Text('Waiting for payment…', style: TextStyle(color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paidView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 56),
          ),
          const SizedBox(height: 20),
          const Text('Payment received', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(formatAmount(widget.session.amount, widget.session.currency),
              style: const TextStyle(fontSize: 18, color: Colors.black54)),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
