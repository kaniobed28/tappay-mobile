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
  // Fall back to treating the whole value as an id.
  return raw.trim();
}

/// Customer entry point: scan a QR code, or tap via NFC.
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
    final available = await nfc.isAvailable();
    if (!available) {
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
      appBar: AppBar(title: const Text('Pay')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(controller: _controller, onDetect: _onDetect),
                // Scan reticle
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                if (_handling)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Scan the merchant QR code',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _tapNfc,
                  icon: const Icon(Icons.contactless, color: AppTheme.brand),
                  label: const Text('Tap with NFC instead'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
