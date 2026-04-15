import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _storageKey = 'kof_current_user';

  final _service = AuthService();
  User? _user;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isGuest => _user?.isGuest ?? false;

  Future<void> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored != null) {
      try {
        _user = User.fromJson(jsonDecode(stored) as Map<String, dynamic>);
        notifyListeners();
      } catch (_) {
        await prefs.remove(_storageKey);
      }
    }
  }

  Future<void> login(String email, String password) async {
    _user = await _service.login(email, password);
    await _persist();
    notifyListeners();
  }

  Future<void> register(
    String name,
    String email,
    String password, {
    String? phone,
  }) async {
    _user = await _service.register(name, email, password, phone: phone);
    await _persist();
    notifyListeners();
  }

  Future<void> loginWithGoogle() async {
    _user = await _service.loginWithGoogle();
    await _persist();
    notifyListeners();
  }

  Future<void> loginWithApple() async {
    _user = await _service.loginWithApple();
    await _persist();
    notifyListeners();
  }

  void loginAsGuest() {
    _user = User.guest();
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_user == null || _user!.isGuest) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_user!.toJson()));
  }
}
