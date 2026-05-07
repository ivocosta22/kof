import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/past_order.dart';
import 'api_service.dart';

class OrderHistoryService {
  static const _basePrefix = 'kof_order_history';
  static const _maxOrders = 50;

  // The active user identifier — orders persist under a key derived from this
  // value so each account (and the shared "guest" bucket) gets its own
  // history. AuthProvider state changes update this via [setCurrentUser].
  static String _userKey = 'guest';

  /// Update the storage scope. Pass the Firebase UID for signed-in users, or
  /// `null` to fall back to the shared `guest` bucket.
  static void setCurrentUser(String? userId) {
    _userKey = (userId == null || userId.isEmpty) ? 'guest' : userId;
  }

  String get _key => '${_basePrefix}__$_userKey';

  Future<List<PastOrder>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    // Force a fresh read from disk — defends against stale in-memory cache
    // when another code path wrote concurrently and we want to see it.
    await prefs.reload();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) {
          try {
            return PastOrder.fromJson(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<PastOrder>()
        .toList();
  }

  Future<void> save(PastOrder order) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.insert(0, jsonEncode(order.toJson()));
    if (raw.length > _maxOrders) raw.removeLast();
    await prefs.setStringList(_key, raw);
  }

  Future<void> updateStatus(int orderId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final updated = raw.map((s) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        if ((map['orderId'] as int?) == orderId) {
          map['status'] = status;
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

  static String _keyFor(String userKey) => '${_basePrefix}__$userKey';

  /// Drop the guest bucket entirely. Used when a guest signs in and declines
  /// the data-transfer prompt — keeps the prompt from re-firing on next sign-in.
  static Future<void> clearGuestBucket() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor('guest'));
  }

  /// Number of orders in the guest bucket — used to decide whether to prompt
  /// for migration when a guest signs in.
  static Future<int> guestOrderCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return (prefs.getStringList(_keyFor('guest')) ?? const []).length;
  }

  /// Move every order from the guest bucket into [targetUid]'s bucket. Newer
  /// guest orders win in case of duplicates. Empties the guest bucket on
  /// success. Caps the resulting list at [_maxOrders].
  static Future<void> migrateGuestToUser(String targetUid) async {
    if (targetUid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final guestKey = _keyFor('guest');
    final userKey = _keyFor(targetUid);
    final guestRaw = prefs.getStringList(guestKey) ?? const [];
    if (guestRaw.isEmpty) return;
    final userRaw = prefs.getStringList(userKey) ?? const [];

    // De-dupe by orderId (string compare on serialised orderId entry).
    final seen = <int>{};
    final merged = <String>[];
    for (final entry in [...guestRaw, ...userRaw]) {
      try {
        final map = jsonDecode(entry) as Map<String, dynamic>;
        final id = map['orderId'] as int?;
        if (id == null || seen.add(id)) merged.add(entry);
      } catch (_) {
        merged.add(entry);
      }
    }
    if (merged.length > _maxOrders) merged.removeRange(_maxOrders, merged.length);

    await prefs.setStringList(userKey, merged);
    await prefs.remove(guestKey);
  }

  // Re-fetch entries that may have stale data: active orders (status can
  // change any moment) and entries with empty items (older saves from before
  // the server returned items on create). Persists fresh values back to local
  // storage. Returns the refreshed list. Failures (offline shop etc.) leave
  // those individual entries untouched.
  Future<List<PastOrder>> refreshFromServer(List<PastOrder> orders) async {
    final candidates = orders.where(
      (o) => (o.isActive || o.items.isEmpty) && o.serverUrl.isNotEmpty,
    );
    if (candidates.isEmpty) return orders;

    final updates = <int, PastOrder>{};
    await Future.wait(candidates.map((entry) async {
      try {
        final fresh = await ApiService(entry.serverUrl).getOrder(entry.orderId);
        updates[entry.orderId] = PastOrder(
          shopName: entry.shopName,
          serverUrl: entry.serverUrl,
          orderId: entry.orderId,
          orderNumber: entry.orderNumber,
          status: fresh.status,
          tableLabel: entry.tableLabel,
          // Only overwrite items if the server actually returned some — avoids
          // wiping a previously good list if the API regresses.
          items: fresh.items.isEmpty ? entry.items : fresh.items,
          createdAt: entry.createdAt,
          totalCents:
              fresh.totalCents > 0 ? fresh.totalCents : entry.totalCents,
        );
      } catch (_) {/* leave entry as-is */}
    }));

    if (updates.isEmpty) return orders;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final rewritten = raw.map((s) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        final id = map['orderId'] as int?;
        final replacement = id == null ? null : updates[id];
        if (replacement == null) return s;
        return jsonEncode(replacement.toJson());
      } catch (_) {
        return s;
      }
    }).toList();
    await prefs.setStringList(_key, rewritten);

    return orders.map((o) => updates[o.orderId] ?? o).toList();
  }
}
