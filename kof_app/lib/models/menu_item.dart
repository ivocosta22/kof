import 'menu_item_size.dart';

class MenuItem {
  final int id;
  final String name;
  final String description;
  final int priceCents;
  final String availability;
  final int? maxMakeableUnits;
  final String category;
  final bool hasSizes;
  final List<MenuItemSize> sizes;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.availability,
    this.maxMakeableUnits,
    this.category = 'Other',
    this.hasSizes = false,
    this.sizes = const [],
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final hasSizes = json['has_sizes'] == true || json['has_sizes'] == 1;
    final sizesJson = json['sizes'] as List<dynamic>?;
    final sizes = sizesJson != null && sizesJson.isNotEmpty
        ? sizesJson
            .map((e) => MenuItemSize.fromJson(e as Map<String, dynamic>))
            .toList()
        : (hasSizes ? kDefaultSizes : const <MenuItemSize>[]);

    return MenuItem(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      priceCents: json['price_cents'] as int,
      availability: json['availability'] as String? ?? 'available',
      maxMakeableUnits: json['max_makeable_units'] as int?,
      category: json['category'] as String? ?? 'Other',
      hasSizes: hasSizes,
      sizes: sizes,
    );
  }

  bool get isOrderable =>
      availability == 'available' ||
      availability == 'low' ||
      availability == 'no_recipe';
}
