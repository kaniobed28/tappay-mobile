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

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handling = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resolveAndReview(String sessionId) async {
    if (_handling) return;
    setState(() => _handling = true);
    final api = context.read<ApiClient>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final session = await api.resolveSession(sessionId);
      if (!mounted) return;
      await navigator.push(MaterialPageRoute(builder: (_) => ReviewScreen(session: session)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _handling = false);
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

  Future<void> _tapNfc() async {
    final nfc = context.read<NfcService>();
    final messenger = ScaffoldMessenger.of(context);
    if (!await nfc.isAvailable()) {
      messenger.showSnackBar(const SnackBar(content: Text('NFC not available on this device')));
      return;
    }
    try {
      final raw = await nfc.readSessionId();
      final id = parseSessionId(raw);
      if (id != null) await _resolveAndReview(id);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('NFC: $e')));
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
          // Dim overlay with a clear window
          const _ScannerOverlay(),
          if (_handling)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Point at the merchant’s QR code',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _tapNfc,
                      icon: const Icon(Icons.contactless_rounded, color: Colors.white),
                      label: const Text('Tap with NFC instead', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.l),
          border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 3),
        ),
        child: Stack(
          children: [
            _corner(Alignment.topLeft),
            _corner(Alignment.topRight),
            _corner(Alignment.bottomLeft),
            _corner(Alignment.bottomRight),
          ],
        ),
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
        decoration: BoxDecoration(
          color: AppColors.brand,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
