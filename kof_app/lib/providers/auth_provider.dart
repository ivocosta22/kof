import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../demo/demo_data.dart';
import '../demo/demo_mode.dart';
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
  // Firebase isn't initialized in demo mode, so any FirebaseAuth call
  // (including the `currentUser` lookup inside _service.isPasswordUser)
  // throws and turns the screen grey. Force-false in demo mode so the
  // account screen shows the read-only Google-style layout.
  bool get isPasswordUser => kDemoMode ? false : _service.isPasswordUser;

  /// Hydrates [_user] from Firebase's persisted session and starts listening
  /// for future auth state changes (sign-in/out on other tabs, token refresh).
  Future<void> tryRestoreSession() async {
    if (kDemoMode) {
      // Demo mode: don't auto-login; the login screen shows a demo button.
      SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
      return;
    }
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
      final priorPhone = _user?.phone;
      final priorCountry = _user?.country;
      _user = _userFromFirebase(fbUser).copyWith(
        phone: priorPhone,
        country: priorCountry,
      );
      _fcm.registerForUser(fbUser.uid);
      notifyListeners();
      // Load country and phone from Firestore
      final results = await Future.wait([
        _userService.getCountry(fbUser.uid),
        _userService.getPhone(fbUser.uid),
      ]);
      if (_user != null && !_user!.isGuest) {
        final country = results[0];
        final phone = results[1];
        if (country != null || phone != null) {
          _user = _user!.copyWith(
            country: country ?? _user!.country,
            phone: phone ?? _user!.phone,
          );
          notifyListeners();
        }
      }
    });
  }

  Future<void> updateProfile({String? name, String? photoUrl}) async {
    if (kDemoMode) {
      _user = _user?.copyWith(name: name, photoUrl: photoUrl);
      notifyListeners();
      return;
    }
    final uid = _user?.id;
    if (uid == null || (_user?.isGuest ?? true)) return;
    await _service.updateProfile(name: name, photoUrl: photoUrl);
    final fbUser = _service.currentFirebaseUser;
    if (fbUser != null && _user != null) {
      _user = _user!.copyWith(
        name: fbUser.displayName ?? _user!.name,
        photoUrl: fbUser.photoURL ?? '',
      );
      notifyListeners();
    }
  }

  Future<void> updateEmail(String newEmail, {String? currentPassword}) =>
      _service.updateEmail(newEmail, currentPassword: currentPassword);

  Future<void> updatePhone(String phone) async {
    if (kDemoMode) {
      _user = _user?.copyWith(phone: phone.trim());
      notifyListeners();
      return;
    }
    final uid = _user?.id;
    if (uid == null || (_user?.isGuest ?? true)) return;
    await _userService.savePhone(uid, phone);
    _user = _user!.copyWith(phone: phone.trim());
    notifyListeners();
  }

  Future<void> saveCountry(String country) async {
    if (kDemoMode) {
      _user = _user?.copyWith(country: country);
      notifyListeners();
      return;
    }
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
    if (phone != null && phone.trim().isNotEmpty) {
      await _userService.savePhone(_user!.id, phone.trim());
    }
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

  void loginAsDemo() {
    _user = DemoData.demoUser;
    notifyListeners();
  }

  /// Polls Firebase for an updated emailVerified flag (call after user
  /// taps "I've verified" on the verification screen).
  Future<bool> refreshEmailVerified() async {
    final refreshed = await _service.reloadCurrentUser();
    if (refreshed != null) {
      _user = refreshed.copyWith(
        phone: _user?.phone ?? refreshed.phone,
        country: _user?.country ?? refreshed.country,
      );
      notifyListeners();
    }
    return _user?.emailVerified ?? false;
  }

  Future<void> resendEmailVerification() => _service.sendEmailVerification();

  Future<void> logout() async {
    if (kDemoMode) {
      _user = null;
      notifyListeners();
      return;
    }
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
