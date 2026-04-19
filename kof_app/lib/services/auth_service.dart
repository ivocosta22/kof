import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';

/// Normalised auth error codes that screens map to localized messages.
enum AuthErrorCode {
  invalidEmail,
  userDisabled,
  userNotFound,
  wrongPassword,
  invalidCredential,
  emailAlreadyInUse,
  weakPassword,
  networkError,
  tooManyRequests,
  googleCancelled,
  googleFailed,
  unknown,
}

class AuthException implements Exception {
  final AuthErrorCode code;
  final String? rawMessage;
  const AuthException(this.code, [this.rawMessage]);

  @override
  String toString() => rawMessage ?? code.name;
}

class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  Stream<fb.User?> authStateChanges() => _auth.authStateChanges();
  fb.User? get currentFirebaseUser => _auth.currentUser;

  Future<User> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _mapUser(cred.user!);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapCode(e.code), e.message);
    }
  }

  Future<User> register(
    String name,
    String email,
    String password, {
    String? phone,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final fbUser = cred.user!;
      await fbUser.updateDisplayName(name);
      await fbUser.sendEmailVerification();
      await fbUser.reload();
      return _mapUser(_auth.currentUser!, fallbackName: name, phone: phone);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapCode(e.code), e.message);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      // Firebase returns user-not-found — but to avoid email enumeration
      // we swallow it and silently succeed, same as a production backend would.
      if (e.code == 'user-not-found' || e.code == 'invalid-email') return;
      throw AuthException(_mapCode(e.code), e.message);
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) return;
    try {
      await user.sendEmailVerification();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapCode(e.code), e.message);
    }
  }

  Future<User?> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    final refreshed = _auth.currentUser;
    return refreshed == null ? null : _mapUser(refreshed);
  }

  Future<User> loginWithGoogle() async {
    final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
    final GoogleSignInAccount? account;
    try {
      account = await googleSignIn.signIn();
    } catch (e) {
      throw AuthException(AuthErrorCode.googleFailed, e.toString());
    }
    if (account == null) {
      throw const AuthException(AuthErrorCode.googleCancelled);
    }

    final auth = await account.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    try {
      final cred = await _auth.signInWithCredential(credential);
      return _mapUser(cred.user!);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapCode(e.code), e.message);
    }
  }

  Future<User> loginWithApple() async {
    // Requires Apple Developer account ($99/year). See TODO.md.
    throw const AuthException(AuthErrorCode.unknown,
        'Apple Sign-In is not yet configured.');
  }

  Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  User _mapUser(fb.User fbUser, {String? fallbackName, String? phone}) {
    return User(
      id: fbUser.uid,
      name: fbUser.displayName ?? fallbackName ?? fbUser.email ?? '',
      email: fbUser.email ?? '',
      phone: phone ?? fbUser.phoneNumber,
      photoUrl: fbUser.photoURL,
      emailVerified: fbUser.emailVerified,
    );
  }

  AuthErrorCode _mapCode(String code) {
    switch (code) {
      case 'invalid-email':
        return AuthErrorCode.invalidEmail;
      case 'user-disabled':
        return AuthErrorCode.userDisabled;
      case 'user-not-found':
        return AuthErrorCode.userNotFound;
      case 'wrong-password':
        return AuthErrorCode.wrongPassword;
      case 'invalid-credential':
        return AuthErrorCode.invalidCredential;
      case 'email-already-in-use':
        return AuthErrorCode.emailAlreadyInUse;
      case 'weak-password':
        return AuthErrorCode.weakPassword;
      case 'network-request-failed':
        return AuthErrorCode.networkError;
      case 'too-many-requests':
        return AuthErrorCode.tooManyRequests;
      default:
        return AuthErrorCode.unknown;
    }
  }
}
