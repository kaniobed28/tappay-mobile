import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../services/nfc_service.dart';
import '../../theme.dart';
import 'review_screen.dart';

/// Extracts a session id from a scanned/tapped payload (`tappay://s/<id>` or a raw id).
String? parseSessionId(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  const prefix = 'tappay://s/';
  if (raw.startsWith(prefix)) return raw.substring(prefix.length);
  return raw.trim();
}

enum _Nfc { checking, ready, off }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handling = false;
  _Nfc _nfc = _Nfc.checking;
  String? _nfcHint;

  @override
  void initState() {
    super.initState();
    // Start NFC listening automatically, in parallel with the QR scanner.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startNfc());
  }

  Future<void> _startNfc() async {
    final nfc = context.read<NfcService>();
    final ok = await nfc.startContinuousRead(
      onId: (raw) {
        final id = parseSessionId(raw);
        if (id != null) _resolveAndReview(id);
      },
      onStatus: (msg) {
        if (mounted) setState(() => _nfcHint = msg);
      },
    );
    if (mounted) setState(() => _nfc = ok ? _Nfc.ready : _Nfc.off);
  }

  @override
  void dispose() {
    context.read<NfcService>().stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resolveAndReview(String sessionId) async {
    if (_handling) return;
    setState(() => _handling = true);
    final api = context.read<ApiClient>();
    final nfc = context.read<NfcService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await nfc.stop();
    try {
      final session = await api.resolveSession(sessionId);
      if (!mounted) return;
      await navigator.push(MaterialPageRoute(builder: (_) => ReviewScreen(session: session)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) {
        setState(() => _handling = false);
        _startNfc(); // resume listening after returning
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handling) return;
    for (final barcode in capture.barcodes) {
      final id = parseSessionId(barcode.rawValue);
      if (id != null && id.isNotEmpty) {
        _resolveAndReview(id);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Pay', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          const _ScannerOverlay(),
          if (_handling)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.88)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Scan the merchant’s QR code',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text('…or tap the two phones back-to-back',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 16),
                  _NfcStatus(state: _nfc, hint: _nfcHint),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NfcStatus extends StatelessWidget {
  final _Nfc state;
  final String? hint;
  const _NfcStatus({required this.state, required this.hint});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (state) {
      _Nfc.checking => (Icons.hourglass_empty_rounded, Colors.white70, 'Preparing NFC…'),
      _Nfc.ready => (Icons.contactless_rounded, AppColors.accent, hint ?? 'NFC ready — hold near the other phone'),
      _Nfc.off => (Icons.nfc_rounded, AppColors.warning, 'NFC is off — turn it on in settings, or use QR'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state == _Nfc.ready) const _LivePulse() else Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _LivePulse extends StatefulWidget {
  const _LivePulse();
  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => SizedBox(
        width: 18,
        height: 18,
        child: Stack(alignment: Alignment.center, children: [
          Container(
            width: 18 * (0.5 + _c.value),
            height: 18 * (0.5 + _c.value),
            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: (1 - _c.value) * 0.5), shape: BoxShape.circle),
          ),
          const Icon(Icons.contactless_rounded, color: AppColors.accent, size: 16),
        ]),
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 248,
        height: 248,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.l),
          border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 3),
        ),
        child: Stack(children: [
          _corner(Alignment.topLeft),
          _corner(Alignment.topRight),
          _corner(Alignment.bottomLeft),
          _corner(Alignment.bottomRight),
        ]),
      ),
    );
  }

  Widget _corner(Alignment a) {
    return Align(
      alignment: a,
      child: Container(
        width: 26,
        height: 26,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
