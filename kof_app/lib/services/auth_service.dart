import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  // Set _devMode = false and implement the real API calls once the
  // platform backend (user accounts) is ready. See TODO.md.
  static const bool _devMode = true;

  Future<User> login(String email, String password) async {
    if (_devMode) return _mockLogin(email, password);
    // TODO: POST /auth/login  { email, password } → { user, token }
    throw UnimplementedError('Platform API not yet configured.');
  }

  Future<User> register(
    String name,
    String email,
    String password, {
    String? phone,
  }) async {
    if (_devMode) return _mockRegister(name, email, password, phone: phone);
    // TODO: POST /auth/register  { name, email, password, phone } → { user, token }
    throw UnimplementedError('Platform API not yet configured.');
  }

  /// In dev mode: verifies the account exists and returns silently (simulates email sent).
  /// In production: POST /auth/forgot-password { email }
  Future<void> sendPasswordReset(String email) async {
    if (_devMode) return _mockSendPasswordReset(email);
    // TODO: POST /auth/forgot-password  { email }
    throw UnimplementedError('Platform API not yet configured.');
  }

  Future<User> loginWithGoogle() async {
    final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
    final account = await googleSignIn.signIn();
    if (account == null) throw Exception('Google Sign-In was cancelled.');
    return User(
      id: 'google_${account.id}',
      name: account.displayName ?? account.email,
      email: account.email,
    );
  }

  Future<User> loginWithApple() async {
    // TODO: Add sign_in_with_apple package + Apple Developer setup. See TODO.md.
    throw Exception(
      'Apple Sign-In is not yet configured.\nSee TODO.md for setup instructions.',
    );
  }

  // ── Mock implementation (dev only) ────────────────────────────────────────

  Future<User> _mockLogin(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('mock_user_${email.toLowerCase()}');
    if (stored == null) throw Exception('No account found with this email.');
    final data = jsonDecode(stored) as Map<String, dynamic>;
    if (data['password'] != password) throw Exception('Incorrect password.');
    return User.fromJson(data);
  }

  Future<void> _mockSendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 700));
    // Silently succeed whether or not the account exists — same behaviour
    // as a real backend (avoids email enumeration attacks).
  }

  Future<User> _mockRegister(
    String name,
    String email,
    String password, {
    String? phone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final prefs = await SharedPreferences.getInstance();
    final key = 'mock_user_${email.toLowerCase()}';
    if (prefs.getString(key) != null) {
      throw Exception('An account with this email already exists.');
    }
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      phone: phone,
    );
    final data = user.toJson()..['password'] = password;
    await prefs.setString(key, jsonEncode(data));
    return user;
  }
}
