# Enabling real Firebase Auth

The app auto-detects Firebase: it runs in **demo auth** until `google-services.json` is
present, then switches to real Firebase automatically ([`AuthService`](lib/services/auth_service.dart)
and the conditional Gradle plugin in [`android/app/build.gradle.kts`](android/app/build.gradle.kts)).
No Dart changes needed.

Firebase project: **tappay-d628e** (you already have the admin service account).

## Mobile (Android)

1. Firebase console → project `tappay-d628e` → **Add app → Android**.
2. Package name: **`com.tappay.tappay`** (exactly). Register.
3. Download **`google-services.json`** → place it at **`mobile/android/app/google-services.json`**.
4. Firebase console → **Authentication → Sign-in method → Email/Password → Enable**.
5. Rebuild:
   ```bash
   flutter build apk --release --dart-define=API_BASE_URL=https://tappay-api.onrender.com/api
   ```

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
