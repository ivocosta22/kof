import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalCents =>
      _items.fold(0, (sum, item) => sum + item.totalCents);

  int get itemCount =>
      _items.fold(0, (sum, item) => sum + item.qty);

  bool get isEmpty => _items.isEmpty;

  void add(MenuItem menuItem) {
    final index = _items.indexWhere((e) => e.menuItem.id == menuItem.id);
    if (index >= 0) {
      _items[index].qty++;
    } else {
      _items.add(CartItem(menuItem: menuItem));
    }
    notifyListeners();
  }

  void decrement(int menuItemId) {
    final index = _items.indexWhere((e) => e.menuItem.id == menuItemId);
    if (index < 0) return;
    if (_items[index].qty > 1) {
      _items[index].qty--;
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  void remove(int menuItemId) {
    _items.removeWhere((e) => e.menuItem.id == menuItemId);
    notifyListeners();
  }

  int qtyFor(int menuItemId) {
    final index = _items.indexWhere((e) => e.menuItem.id == menuItemId);
    return index >= 0 ? _items[index].qty : 0;
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
              'chosen_modifiers': <String>[],
            })
        .toList();
  }
}
