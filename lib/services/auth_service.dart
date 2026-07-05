import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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

  Future<void> signOut() async {
    if (_firebaseReady) {
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
