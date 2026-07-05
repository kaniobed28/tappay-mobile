import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Registers the device's FCM token with the backend so it can receive push notifications.
/// No-op when Firebase isn't configured (dev mode) — FCM requires a real Firebase project.
class PushService {
  Future<void> register(ApiClient api, {required bool firebaseReady}) async {
    if (!firebaseReady) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null) return;

      final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      // MVP: use the FCM token as the device id too. A rotating token creates a new device
      // row; the backend prunes dead tokens on send.
      await api.registerDevice(deviceId: token, platform: platform, pushToken: token);

      // Keep the backend in sync if FCM rotates the token.
      messaging.onTokenRefresh.listen((t) {
        api.registerDevice(deviceId: t, platform: platform, pushToken: t);
      });
    } catch (e) {
      debugPrint('Push registration skipped: $e');
    }
  }
}
