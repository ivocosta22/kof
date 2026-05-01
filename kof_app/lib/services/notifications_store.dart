import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';

/// Persists the current user's received notifications. Keyed per user (or
/// `guest`) so logging out / switching account doesn't leak someone else's
/// inbox. Same pattern as OrderHistoryService.
class NotificationsStore {
  static const _basePrefix = 'kof_notifications';
  static const _maxItems = 100;

  // Active scope — set via [setCurrentUser] from auth state changes.
  static String _userKey = 'guest';

  static void setCurrentUser(String? userId) {
    _userKey = (userId == null || userId.isEmpty) ? 'guest' : userId;
  }

  String get _key => '${_basePrefix}__$_userKey';

  Future<List<NotificationItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    // Force a fresh read in case another isolate (background message handler)
    // wrote to the same key.
    await prefs.reload();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    return raw
        .map((s) {
          try {
            return NotificationItem.fromJson(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<NotificationItem>()
        .toList();
  }

  Future<void> save(NotificationItem item) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final raw = prefs.getStringList(_key) ?? <String>[];

    // De-duplicate by id — FCM occasionally redelivers the same message and
    // tap-to-open paths can race with foreground delivery.
    final filtered = raw.where((s) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        return (map['id'] as String?) != item.id;
      } catch (_) {
        return true;
      }
    }).toList();

    filtered.insert(0, jsonEncode(item.toJson()));
    if (filtered.length > _maxItems) {
      filtered.removeRange(_maxItems, filtered.length);
    }
    await prefs.setStringList(_key, filtered);
  }

  Future<void> markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final raw = prefs.getStringList(_key) ?? <String>[];
    final updated = raw.map((s) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        if (map['read'] != true) {
          map['read'] = true;
          return jsonEncode(map);
        }
      } catch (_) {}
      return s;
    }).toList();
    await prefs.setStringList(_key, updated);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
