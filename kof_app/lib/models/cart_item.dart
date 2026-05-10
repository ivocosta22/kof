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

  Map<String, dynamic> toJson() => {
        'menuItem': menuItem.toJson(),
        'size': size?.toJson(),
        'qty': qty,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final sizeJson = json['size'] as Map<String, dynamic>?;
    return CartItem(
      menuItem: MenuItem.fromJson(json['menuItem'] as Map<String, dynamic>),
      size: sizeJson != null ? MenuItemSize.fromJson(sizeJson) : null,
      qty: (json['qty'] as num?)?.toInt() ?? 1,
    );
  }
}
