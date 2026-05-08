import 'package:flutter/services.dart';

/// App-wide haptic helper. Reads a single static flag so any widget can
/// trigger feedback without going through Provider — `SettingsProvider`
/// keeps the flag in sync whenever the user toggles the setting.
class Haptics {
  static bool enabled = true;

  /// Lightweight tap — buttons, selection changes, list-item taps.
  static void selection() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Slightly stronger — primary actions like "Place Order", "Apply".
  static void light() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Used for destructive or significant moments — logout confirmation,
  /// successful order placement.
  static void medium() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }
}
