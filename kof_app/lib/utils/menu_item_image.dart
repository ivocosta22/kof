import 'package:flutter/material.dart';

// Maps menu item names to bundled cup-illustration assets. Names are matched
// case-insensitively against substrings — this lets shops use "Iced Latte" or
// "House Iced Latte" and still get the same image.
//
// Returns null if the item has no matching asset (caller should render a
// generic placeholder instead).

const _imageMap = <String, String>{
  'espresso': 'assets/images/image_espresso.png',
  'cappuccino': 'assets/images/image_cappuccino.png',
  'iced latte': 'assets/images/image_icedLatte.png',
  'iced coffee': 'assets/images/image_icedLatte.png',
  'cold brew': 'assets/images/image_icedLatte.png',
  'americano': 'assets/images/image_espresso.png',
  'latte': 'assets/images/image_cappuccino.png',
  'mocha': 'assets/images/image_cappuccino.png',
  'hot chocolate': 'assets/images/image_cappuccino.png',
};

String? imageAssetForItem(String itemName) {
  final lower = itemName.toLowerCase();
  // Prefer the longest matching key so "iced latte" wins over "latte".
  final keys = _imageMap.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final key in keys) {
    if (lower.contains(key)) return _imageMap[key];
  }
  return null;
}

// Fallback icon used wherever a menu item has no bundled cup illustration.
// Tries to be specific by item name first (chocolate muffin, croissant,
// avocado toast, etc.), then falls back to the broader category icon.
IconData iconForMenuItem({required String name, required String category}) {
  final lower = name.toLowerCase();

  if (lower.contains('muffin') || lower.contains('cupcake')) {
    return Icons.cake;
  }
  if (lower.contains('croissant')) return Icons.bakery_dining;
  if (lower.contains('cinnamon') || lower.contains('roll') ||
      lower.contains('donut') || lower.contains('doughnut')) {
    return Icons.donut_large;
  }
  if (lower.contains('cookie')) return Icons.cookie;
  if (lower.contains('avocado') || lower.contains('toast') ||
      lower.contains('toastie') || lower.contains('sandwich') ||
      lower.contains('bagel')) {
    return Icons.lunch_dining;
  }
  if (lower.contains('tea')) return Icons.emoji_food_beverage;
  if (lower.contains('chocolate') &&
      (category != 'Pastries' && category != 'Food')) {
    // "Hot Chocolate" / "Mocha" — drink, not pastry.
    return Icons.coffee;
  }

  return iconForCategory(category);
}

IconData iconForCategory(String category) {
  return switch (category) {
    'Espresso' => Icons.local_cafe,
    'Hot Drinks' => Icons.coffee,
    'Cold Drinks' => Icons.local_drink,
    'Pastries' => Icons.bakery_dining,
    'Food' => Icons.lunch_dining,
    _ => Icons.restaurant,
  };
}
