import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/menu_item_size.dart';
import '../models/table_session.dart';

/// A snapshot of a cart that was left behind for a particular shop. The
/// floating cart bubble surfaces these so the user can resume an order they
/// hadn't yet placed.
class SavedCart {
  final TableSession session;
  final List<CartItem> items;

  const SavedCart({required this.session, required this.items});

  int get itemCount => items.fold(0, (sum, item) => sum + item.qty);
  int get totalCents => items.fold(0, (sum, item) => sum + item.totalCents);

  Map<String, dynamic> toJson() => {
        'session': session.toJson(),
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory SavedCart.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>? ?? const []);
    return SavedCart(
      session: TableSession.fromJson(json['session'] as Map<String, dynamic>),
      items: itemsJson
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CartProvider extends ChangeNotifier {
  static const _storageKey = 'kof_carts_v1';

  final List<CartItem> _items = [];
  TableSession? _activeSession;
  final Map<String, SavedCart> _saved = {};
  bool _hydrated = false;

  List<CartItem> get items => List.unmodifiable(_items);

  TableSession? get activeSession => _activeSession;

  /// Carts saved for shops other than (or in addition to) the active session.
  /// Empty carts are not surfaced.
  List<SavedCart> get savedCarts =>
      _saved.values.where((c) => c.items.isNotEmpty).toList();

  int get totalCents => _items.fold(0, (sum, item) => sum + item.totalCents);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.qty);

  bool get isEmpty => _items.isEmpty;

  String _keyFor(int menuItemId, String sizeName) =>
      '$menuItemId|$sizeName';

  /// Read the persisted carts off disk. Safe to call repeatedly — only the
  /// first call hits storage. Should be awaited at startup before showing UI
  /// that depends on saved-cart visibility (e.g. the floating bubble).
  Future<void> hydrate() async {
    if (_hydrated) return;
    _hydrated = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _saved.clear();
      for (final entry in map.entries) {
        try {
          _saved[entry.key] =
              SavedCart.fromJson(entry.value as Map<String, dynamic>);
        } catch (_) {/* drop malformed entries */}
      }
      notifyListeners();
    } catch (_) {/* corrupt blob — ignore */}
  }

  /// Switch which shop's cart is currently being edited. Persists the
  /// previously-active items into the saved map and loads any items that were
  /// previously saved for [session].
  ///
  /// Starting an order at a new shop drops every *other* shop's saved cart —
  /// the user only ever holds one cart at a time, so items from a previous
  /// store can't bleed into a fresh order.
  Future<void> setActiveSession(TableSession? session) async {
    if (!_hydrated) await hydrate();

    // Snapshot the current items into the saved-cart map for the previous
    // shop so the floating bubble keeps surfacing it while the session is
    // unset (e.g. user is on the home screen).
    final prev = _activeSession;
    if (prev != null) {
      if (_items.isEmpty) {
        _saved.remove(prev.serverUrl);
      } else {
        _saved[prev.serverUrl] = SavedCart(
          session: prev,
          items: _items.map((i) => CartItem(
                menuItem: i.menuItem,
                size: i.size,
                qty: i.qty,
              )).toList(),
        );
      }
    }

    // Switching to a real session: drop every saved cart that doesn't belong
    // to this shop. The previous shop's items (just saved above) get cleared
    // here when the user starts ordering elsewhere.
    if (session != null) {
      _saved.removeWhere((url, _) => url != session.serverUrl);
    }

    _activeSession = session;
    _items.clear();
    if (session != null) {
      final saved = _saved[session.serverUrl];
      if (saved != null) {
        _items.addAll(saved.items.map((i) => CartItem(
              menuItem: i.menuItem,
              size: i.size,
              qty: i.qty,
            )));
        // Refresh the session metadata in case shopName/customerLabel changed.
        _saved[session.serverUrl] =
            SavedCart(session: session, items: saved.items);
      }
    }

    await _persist();
    notifyListeners();
  }

  void add(MenuItem menuItem, {MenuItemSize? size, int qty = 1}) {
    final key = _keyFor(menuItem.id, size?.name ?? '');
    final index = _items.indexWhere((e) => e.lineKey == key);
    if (index >= 0) {
      _items[index].qty += qty;
    } else {
      _items.add(CartItem(menuItem: menuItem, size: size, qty: qty));
    }
    _scheduleSave();
    notifyListeners();
  }

  void decrementLine(String lineKey) {
    final index = _items.indexWhere((e) => e.lineKey == lineKey);
    if (index < 0) return;
    if (_items[index].qty > 1) {
      _items[index].qty--;
    } else {
      _items.removeAt(index);
    }
    _scheduleSave();
    notifyListeners();
  }

  void removeLine(String lineKey) {
    _items.removeWhere((e) => e.lineKey == lineKey);
    _scheduleSave();
    notifyListeners();
  }

  // Total quantity across all sizes for a given menu item — used by the menu
  // list to show a small badge "in cart" indicator.
  int qtyFor(int menuItemId) {
    return _items
        .where((e) => e.menuItem.id == menuItemId)
        .fold(0, (sum, e) => sum + e.qty);
  }

  /// Wipe the active cart and remove its persisted entry. Used after placing
  /// an order or when the user explicitly resets state (e.g. logout).
  void clear() {
    _items.clear();
    if (_activeSession != null) {
      _saved.remove(_activeSession!.serverUrl);
    }
    _scheduleSave();
    notifyListeners();
  }

  /// Discard a saved cart for a shop that isn't the active one (e.g. user
  /// dismisses the floating bubble for that shop).
  Future<void> discardSavedCart(String serverUrl) async {
    if (_saved.remove(serverUrl) == null) return;
    if (_activeSession?.serverUrl == serverUrl) {
      _items.clear();
    }
    await _persist();
    notifyListeners();
  }

  /// Wipe everything — current cart, every saved cart, and the persisted
  /// blob. Used on logout where the user is leaving the account context
  /// entirely.
  Future<void> clearAll() async {
    _items.clear();
    _saved.clear();
    _activeSession = null;
    await _persist();
    notifyListeners();
  }

  List<Map<String, dynamic>> toOrderItems() {
    return _items
        .map((e) => {
              'menu_item_id': e.menuItem.id,
              'qty': e.qty,
              'size': e.sizeName,
              'chosen_modifiers': <String>[],
            })
        .toList();
  }

  // Fire-and-forget persistence. Mutations call this and continue without
  // awaiting — disk writes happen in the background.
  void _scheduleSave() {
    // Mirror current items into saved bucket so persist is a single read of
    // _saved.
    final session = _activeSession;
    if (session != null) {
      if (_items.isEmpty) {
        _saved.remove(session.serverUrl);
      } else {
        _saved[session.serverUrl] = SavedCart(
          session: session,
          items: _items.map((i) => CartItem(
                menuItem: i.menuItem,
                size: i.size,
                qty: i.qty,
              )).toList(),
        );
      }
    }
    _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_saved.isEmpty) {
        await prefs.remove(_storageKey);
        return;
      }
      final map =
          _saved.map((url, cart) => MapEntry(url, cart.toJson()));
      await prefs.setString(_storageKey, jsonEncode(map));
    } catch (_) {/* best-effort persistence */}
  }
}
