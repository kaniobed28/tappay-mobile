import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thrown when a provider that needs a live Firebase project is used in demo mode.
class FirebaseRequired implements Exception {
  final String message;
  FirebaseRequired(this.message);
  @override
  String toString() => message;
}

/// Wraps Firebase Auth, with a graceful **dev fallback** so the app is usable before a
/// Firebase project is wired up. When Firebase can't initialize (no config files), the
/// service issues `dev:<uid>:<email>` tokens that the backend accepts in non-production.
class AuthService extends ChangeNotifier {
  bool _firebaseReady = false;
  bool get firebaseReady => _firebaseReady;

  // Dev-mode identity (only used when Firebase is unavailable).
  String? _devUid;
  String? _devEmail;

  User? _firebaseUser;

  bool get isSignedIn => _firebaseReady ? _firebaseUser != null : _devUid != null;
  String? get email => _firebaseReady ? _firebaseUser?.email : _devEmail;
  String? get uid => _firebaseReady ? _firebaseUser?.uid : _devUid;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
      FirebaseAuth.instance.authStateChanges().listen((u) {
        _firebaseUser = u;
        notifyListeners();
      });
      _firebaseUser = FirebaseAuth.instance.currentUser;
    } catch (e) {
      // No Firebase config — fall back to dev auth so the flow still works locally.
      _firebaseReady = false;
      debugPrint('Firebase unavailable, using dev auth mode: $e');
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    if (_firebaseReady) {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } else {
      _devSignIn(email);
    }
  }

  Future<void> register(String email, String password) async {
    if (_firebaseReady) {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } else {
      _devSignIn(email);
    }
  }

  void _devSignIn(String email) {
    _devEmail = email.trim();
    _devUid = 'dev_${email.trim().hashCode.toRadixString(16)}';
    notifyListeners();
  }

  static const _needsFirebase =
      'This sign-in method needs Firebase. Enable it (see FIREBASE.md), then rebuild.';

  /// Google sign-in. Requires a live Firebase project + OAuth client (google-services.json).
  Future<void> signInWithGoogle() async {
    if (!_firebaseReady) throw FirebaseRequired(_needsFirebase);
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return; // user cancelled
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  /// Starts phone verification. Requires Firebase with the Phone provider enabled.
  /// `codeSent` receives a verificationId to pass to [confirmPhoneCode].
  Future<void> startPhoneSignIn({
    required String phoneNumber,
    required void Function(String verificationId) codeSent,
    required void Function(String message) onError,
  }) async {
    if (!_firebaseReady) {
      onError(_needsFirebase);
      return;
    }
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      verificationCompleted: (cred) async {
        try {
          await FirebaseAuth.instance.signInWithCredential(cred);
        } catch (_) {/* auto-retrieval; ignore if manual code also entered */}
      },
      verificationFailed: (e) => onError(e.message ?? 'Verification failed'),
      codeSent: (verificationId, _) => codeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Completes phone sign-in with the SMS code the user typed.
  Future<void> confirmPhoneCode(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    if (_firebaseReady) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {/* not signed in via Google */}
      await FirebaseAuth.instance.signOut();
    } else {
      _devUid = null;
      _devEmail = null;
      notifyListeners();
    }
  }

  /// Returns the bearer token for API calls (Firebase ID token, or a dev token).
  Future<String?> getIdToken() async {
    if (_firebaseReady) {
      return _firebaseUser?.getIdToken();
    }
    if (_devUid == null) return null;
    return 'dev:$_devUid:${_devEmail ?? ''}';
  }
}
