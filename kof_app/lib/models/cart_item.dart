import 'menu_item.dart';
import 'menu_item_size.dart';

class CartItem {
  final MenuItem menuItem;
  final MenuItemSize? size;
  int qty;

  CartItem({required this.menuItem, this.size, this.qty = 1});

  int get unitPriceCents =>
      menuItem.priceCents + (size?.priceCentsDelta ?? 0);

  int get totalCents => unitPriceCents * qty;

  String get sizeName => size?.name ?? '';

  // Stable key combining menu item id + size name; used to merge or split
  // duplicate cart entries.
  String get lineKey => '${menuItem.id}|$sizeName';
}
