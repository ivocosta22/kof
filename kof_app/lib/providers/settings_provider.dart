import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyHaptic = 'setting_haptic_feedback';
  static const _keyTheme = 'setting_theme_mode';
  static const _keyLocale = 'setting_locale';

  bool _hapticFeedback = true;
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale; // null = follow system

  bool get hapticFeedback => _hapticFeedback;
  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _hapticFeedback = prefs.getBool(_keyHaptic) ?? true;

    final themeStr = prefs.getString(_keyTheme);
    _themeMode = switch (themeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final localeStr = prefs.getString(_keyLocale);
    _locale = localeStr != null ? Locale(localeStr) : null;

    notifyListeners();
  }

  Future<void> setHapticFeedback(bool value) async {
    _hapticFeedback = value;
    notifyListeners();
    if (value) HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHaptic, value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final str = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await prefs.setString(_keyTheme, str);
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_keyLocale);
    } else {
      await prefs.setString(_keyLocale, locale.languageCode);
    }
  }
}
