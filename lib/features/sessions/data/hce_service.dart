import 'package:flutter/services.dart';

/// Bridges to the Android HCE service so the merchant phone broadcasts the payment
/// session as a virtual NFC tag — the customer just taps phones, no physical tag needed.
///
/// On iOS (no HCE for third parties) every call degrades gracefully to "unsupported",
/// and the QR code remains the universal channel.
class HceService {
  static const _channel = MethodChannel('tappay/hce');

  Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } catch (_) {
      return false; // iOS / no NFC hardware / channel unavailable
    }
  }

  /// Starts broadcasting [text] to any phone that taps this one.
  Future<bool> broadcast(String text) async {
    try {
      return await _channel.invokeMethod<bool>('setPayload', {'text': text}) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod('clearPayload');
    } catch (_) {/* nothing to clean up */}
  }
}
