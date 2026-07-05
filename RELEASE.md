# TapPay — production release notes

## App identity
- Name: **TapPay** · package `com.tappay.tappay` · version in `pubspec.yaml` (`1.0.0+1`)
- Branded adaptive launcher icon + splash screen (source art in `branding/`, regenerate with
  `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`).

## Release signing ⚠️ back this up
Release builds are signed with **`android/app/tappay-release.jks`** (config in
`android/key.properties`). **Both files are git-ignored.**

> **Losing the keystore means you can never update the app on the Play Store.**
> Back up `tappay-release.jks` and `key.properties` somewhere safe (password manager /
> encrypted storage). They only exist on this machine.

Fingerprints of the release cert:
```
SHA-1:   07:2B:6A:B4:C5:9F:03:CB:C6:DA:71:81:36:2F:E3:2B:FB:12:CE:29
SHA-256: A5:60:78:1B:67:27:66:4C:71:4E:E5:5C:D7:FA:0D:54:88:DD:40:81:37:F2:49:B5:14:79:0C:D3:3B:C7:CC:D8
```

### Add the release SHA to Firebase (required for Google & Phone sign-in)
Google/Phone auth verify the app's signing certificate. After switching to the release key,
add the **release SHA‑1 and SHA‑256 above** in Firebase → Project settings → Your apps →
Android → *Add fingerprint*. (Email sign-in and Paystack don't need this.)

If you later use **Play App Signing**, also add the Play-managed SHA‑1/256 from the Play
Console, and re-download `google-services.json`.

## Build
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://tappay-api.onrender.com/api
# or, for Play Store upload:
flutter build appbundle --release --dart-define=API_BASE_URL=https://tappay-api.onrender.com/api
```
Release builds are **minified/shrunk with R8** (`isMinifyEnabled`, `proguard-rules.pro`).

## Pre-launch checklist
- [ ] Release SHA‑1/256 added to Firebase (Google/Phone)
- [ ] Keystore backed up
- [ ] Backend `ALLOW_DEV_AUTH=false` on Render (real Firebase only)
- [ ] Paystack switched from test to **live** keys when going to real money
- [ ] Bump `version:` in pubspec for each store submission
