import 'menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  int qty;

  CartItem({required this.menuItem, this.qty = 1});

  int get totalCents => menuItem.priceCents * qty;
}
