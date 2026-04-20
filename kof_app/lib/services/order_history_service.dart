import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/past_order.dart';

class OrderHistoryService {
  static const _key = 'kof_order_history';
  static const _maxOrders = 50;

  Future<List<PastOrder>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
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
}
