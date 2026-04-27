import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/menu_item_size.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalCents =>
      _items.fold(0, (sum, item) => sum + item.totalCents);

  int get itemCount =>
      _items.fold(0, (sum, item) => sum + item.qty);

  bool get isEmpty => _items.isEmpty;

  String _keyFor(int menuItemId, String sizeName) =>
      '$menuItemId|$sizeName';

  void add(MenuItem menuItem, {MenuItemSize? size, int qty = 1}) {
    final key = _keyFor(menuItem.id, size?.name ?? '');
    final index = _items.indexWhere((e) => e.lineKey == key);
    if (index >= 0) {
      _items[index].qty += qty;
    } else {
      _items.add(CartItem(menuItem: menuItem, size: size, qty: qty));
    }
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
    notifyListeners();
  }

  void removeLine(String lineKey) {
    _items.removeWhere((e) => e.lineKey == lineKey);
    notifyListeners();
  }

  // Total quantity across all sizes for a given menu item — used by the menu
  // list to show a small badge "in cart" indicator.
  int qtyFor(int menuItemId) {
    return _items
        .where((e) => e.menuItem.id == menuItemId)
        .fold(0, (sum, e) => sum + e.qty);
  }

  void clear() {
    _items.clear();
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
}
