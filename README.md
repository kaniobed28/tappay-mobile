# TapPay Mobile

Flutter app for TapPay — tap (NFC) or scan (QR) to pay, with Firebase Auth. Payment is
completed whichever way the backend's provider works: an approval prompt on the payer's
phone (MTN MoMo, the default) or a provider-hosted checkout page (Paystack).

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
  [`AuthService`](lib/features/auth/data/auth_service.dart) auto-detects Firebase and switches over.

## Flows

- **Receive (merchant):** set business name → enter amount → a signed session renders as a
  QR code and can be sent over NFC. The screen polls until the payment confirms.
- **Pay (customer):** scan the QR (or tap NFC) → review merchant/amount → confirm → finish
  the payment the way the provider works — a checkout page in a webview (card/bank), or by
  approving the prompt on your own phone (mobile money) while the app waits → the result
  screen reflects the server-verified status.

## Structure

Feature-first: everything one feature needs lives in its folder, and features are named
after the same slices as the backend's modules.

```
lib/
  main.dart              entrypoint
  app/
    app.dart             root widget + signed-in/out gate
    dependencies.dart    all DI wiring, in one place
  core/                  shared by every feature, owned by none
    config/              API base URL, callback scheme
    network/             Dio transport (auth header, retry) + error helpers
    realtime/            socket.io client
    theme/  widgets/     brand theme, shared UI
  features/
    <feature>/
      data/              its API client, models, device services
      presentation/      its screens
```

The features are `auth`, `home`, `users`, `merchants`, `sessions` (tap/QR hand-off),
`payments`, `requests`, `notifications`, `receipts`.

Each feature exposes exactly one API object (`PaymentsApi`, `SessionsApi`, …) over the
shared transport, so a screen depends on its own feature's API rather than on one client
that knows every endpoint. Imports are package-absolute (`package:tappay/…`), so moving a
file doesn't ripple.

## Notes on NFC

True phone-to-phone NFC broadcast requires host card emulation (Android HCE service; iOS is
read-only for tags) and is a platform-specific enhancement beyond this MVP. NFC here reads/writes
the session id to an NFC tag/reader; **QR is the guaranteed universal channel**. Both carry the
same signed session id — security is enforced by the backend signature, not the transport.
