import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  final FcmService _fcm = FcmService();
  final UserService _userService = UserService();
  StreamSubscription<fb.User?>? _sub;
  User? _user;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isGuest => _user?.isGuest ?? false;
  bool get emailVerified => _user?.emailVerified ?? false;

  /// Hydrates [_user] from Firebase's persisted session and starts listening
  /// for future auth state changes (sign-in/out on other tabs, token refresh).
  Future<void> tryRestoreSession() async {
    _attachListener();
    final fbUser = _service.currentFirebaseUser;
    if (fbUser != null) _user = _userFromFirebase(fbUser);
    SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  void _attachListener() {
    _sub ??= _service.authStateChanges().listen((fbUser) async {
      // Don't clobber an active guest session when Firebase reports null.
      if (fbUser == null) {
        if (_user != null && !_user!.isGuest) {
          _user = null;
          _fcm.unregister();
          notifyListeners();
        }
        return;
      }
      _user = _userFromFirebase(fbUser);
      _fcm.registerForUser(fbUser.uid);
      notifyListeners();
      // Load country from Firestore and update if present
      final country = await _userService.getCountry(fbUser.uid);
      if (country != null && _user != null && !_user!.isGuest) {
        _user = _user!.copyWith(country: country);
        notifyListeners();
      }
    });
  }

  Future<void> saveCountry(String country) async {
    final uid = _user?.id;
    if (uid == null || (_user?.isGuest ?? true)) return;
    await _userService.saveCountry(uid, country);
    _user = _user!.copyWith(country: country);
    notifyListeners();
  }

  User _userFromFirebase(fb.User f) => User(
        id: f.uid,
        name: f.displayName ?? f.email ?? '',
        email: f.email ?? '',
        phone: f.phoneNumber,
        photoUrl: f.photoURL,
        emailVerified: f.emailVerified,
      );

  Future<void> login(String email, String password) async {
    _user = await _service.login(email, password);
    notifyListeners();
  }

  Future<void> register(
    String name,
    String email,
    String password, {
    String? phone,
  }) async {
    _user = await _service.register(name, email, password, phone: phone);
    notifyListeners();
  }

  Future<void> loginWithGoogle() async {
    _user = await _service.loginWithGoogle();
    notifyListeners();
  }

  Future<void> loginWithApple() async {
    _user = await _service.loginWithApple();
    notifyListeners();
  }

  void loginAsGuest() {
    _user = User.guest();
    notifyListeners();
  }

  /// Polls Firebase for an updated emailVerified flag (call after user
  /// taps "I've verified" on the verification screen).
  Future<bool> refreshEmailVerified() async {
    final refreshed = await _service.reloadCurrentUser();
    if (refreshed != null) {
      _user = refreshed;
      notifyListeners();
    }
    return _user?.emailVerified ?? false;
  }

  Future<void> resendEmailVerification() => _service.sendEmailVerification();

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
