import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/past_order.dart';
import 'api_service.dart';

class OrderHistoryService {
  static const _key = 'kof_order_history';
  static const _maxOrders = 50;

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
