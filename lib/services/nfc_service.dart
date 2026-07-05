import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';

/// NFC transport for exchanging a payment-session id between devices.
///
/// Note on phone-to-phone NFC: true host-card-emulation "broadcast" from a phone is a
/// platform-specific enhancement (Android HCE service / iOS is read-only for tags). For
/// the MVP, NFC is used to **read/write the session id** to an NFC tag or reader, and the
/// QR code is the guaranteed universal channel that works on every device. Both carry the
/// same signed session id — the security lives in the backend signature, not the transport.
class NfcService {
  Future<bool> isAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Reads a session id from a tapped tag/device. Completes with the id or throws.
  Future<String> readSessionId({Duration timeout = const Duration(seconds: 30)}) async {
    final completer = Completer<String>();

    await NfcManager.instance.startSession(
      alertMessage: 'Hold near the TapPay merchant to pay',
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            throw Exception('Tag is not NDEF formatted');
          }
          final message = await ndef.read();
          final text = _firstText(message);
          if (text == null) throw Exception('No TapPay data on tag');
          if (!completer.isCompleted) completer.complete(text);
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        } finally {
          await NfcManager.instance.stopSession();
        }
      },
    );

    return completer.future.timeout(timeout, onTimeout: () async {
      await NfcManager.instance.stopSession();
      throw TimeoutException('No tag detected');
    });
  }

  /// Writes a session id onto a writable NFC tag presented to the merchant device.
  Future<void> writeSessionId(String sessionId, {Duration timeout = const Duration(seconds: 30)}) async {
    final completer = Completer<void>();

    await NfcManager.instance.startSession(
      alertMessage: 'Hold the customer device / tag near to send',
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            throw Exception('Tag is not writable');
          }
          await ndef.write(NdefMessage([NdefRecord.createText(sessionId)]));
          if (!completer.isCompleted) completer.complete();
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        } finally {
          await NfcManager.instance.stopSession();
        }
      },
    );

    return completer.future.timeout(timeout, onTimeout: () async {
      await NfcManager.instance.stopSession();
      throw TimeoutException('No tag detected');
    });
  }

  Future<void> stop() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }

  /// Decodes the first NDEF text record's payload (status byte + lang code + UTF-8 text).
  String? _firstText(NdefMessage message) {
    for (final record in message.records) {
      final payload = record.payload;
      if (payload.isEmpty) continue;
      final Uint8List bytes = payload;
      final int langLen = bytes[0] & 0x3F;
      if (bytes.length <= 1 + langLen) continue;
      return utf8.decode(bytes.sublist(1 + langLen));
    }
    return null;
  }
}
