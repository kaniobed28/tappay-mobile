# Enabling real Firebase Auth

The app auto-detects Firebase: it runs in **demo auth** until `google-services.json` is
present, then switches to real Firebase automatically ([`AuthService`](lib/features/auth/data/auth_service.dart)
and the conditional Gradle plugin in [`android/app/build.gradle.kts`](android/app/build.gradle.kts)).
No Dart changes needed.

Firebase project: **tappay-d628e** (you already have the admin service account).

## Mobile (Android)

1. Firebase console → project `tappay-d628e` → **Add app → Android**.
2. Package name: **`com.tappay.tappay`** (exactly).
3. **Add your SHA‑1 and SHA‑256** (required for Google sign-in and Phone auth on Android).
   Get them from the debug keystore (the app's release build is debug-signed by default):
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   Copy the `SHA1` and `SHA-256` lines into the Firebase Android app settings (you can add
   fingerprints after registering, under Project settings → Your apps).
4. Download **`google-services.json`** → place it at **`mobile/android/app/google-services.json`**.
5. Firebase console → **Authentication → Sign-in method** → enable the ones you want:
   - **Email/Password**
   - **Google** (pick a support email)
   - **Phone** — add a test number + code under *Phone numbers for testing* to try it without real SMS.
6. Rebuild:
   ```bash
   flutter build apk --release --dart-define=API_BASE_URL=https://tappay-api.onrender.com/api
   ```

The login screen already shows **Continue with Google** and **Continue with phone** — they
activate automatically once the above is done. Until then they show a "needs Firebase" message.

## Backend (Render)

1. Open the admin service account JSON you downloaded and copy its **entire contents**.
2. Render → `tappay-api` → **Environment**:
   - Add `FIREBASE_SERVICE_ACCOUNT_JSON` = *(paste the full JSON)*
   - Set `ALLOW_DEV_AUTH` = `false`
3. Save → it redeploys. The backend now verifies real Firebase ID tokens and the insecure
   demo bypass is off.

> Do both sides together: once the backend requires real Firebase, the app must also send
> real Firebase tokens (i.e. have `google-services.json`), or sign-in will be rejected.

`google-services.json` is git-ignored — never commit it.
