# TapPay Mobile

Flutter app for TapPay — tap (NFC) or scan (QR) to pay, with Firebase Auth and a
provider-hosted checkout (Paystack by default).

## Prerequisites

- Flutter 3.4+ (Dart 3.12+)
- Android device/emulator (NFC needs a physical device; QR needs a camera)
- The [backend](../backend) running and reachable

## Run

```bash
cd mobile
flutter pub get
flutter run                # talks to the deployed API by default
```

With no `--dart-define`, the app uses the deployed backend
(`https://tappay-api.onrender.com/api`), so it works on any device out of the box.
To point at a local backend instead (port comes from `backend/.env`, currently **8090**):

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8090/api
```

`10.0.2.2` is the Android emulator's alias for your host machine. On a physical device,
use your machine's LAN IP (e.g. `http://192.168.1.20:8090/api`).

## Auth: dev mode vs Firebase

- **Dev mode (default, no setup):** if Firebase isn't configured, the app signs in with any
  email/password and sends `dev:<uid>` tokens that the backend accepts in non-production.
  This lets you exercise the full pay/receive flow immediately.
- **Firebase:** run `flutterfire configure` (or add `google-services.json` /
  `GoogleService-Info.plist`) to enable real Firebase Auth. No code change needed —
  [`AuthService`](lib/services/auth_service.dart) auto-detects Firebase and switches over.

## Flows

- **Receive (merchant):** set business name → enter amount → a signed session renders as a
  QR code and can be sent over NFC. The screen polls until the payment confirms.
- **Pay (customer):** scan the QR (or tap NFC) → review merchant/amount → confirm → the
  provider checkout opens in a webview → the result screen reflects the server-verified status.

## Structure

```
lib/
  config.dart            API base URL, callback scheme
  theme.dart             brand theme + amount formatting
  models/models.dart     API DTOs
  services/
    auth_service.dart    Firebase Auth (+ dev fallback)
    api_client.dart      typed Dio client w/ bearer interceptor
    nfc_service.dart     NFC read/write of the session id
  screens/
    auth/                login / register
    home_screen.dart     dashboard + bottom nav
    receive/             merchant: amount -> QR/NFC collect
    pay/                 customer: scan -> review -> checkout -> result
    history/             transaction activity
```

## Notes on NFC

True phone-to-phone NFC broadcast requires host card emulation (Android HCE service; iOS is
read-only for tags) and is a platform-specific enhancement beyond this MVP. NFC here reads/writes
the session id to an NFC tag/reader; **QR is the guaranteed universal channel**. Both carry the
same signed session id — security is enforced by the backend signature, not the transport.
