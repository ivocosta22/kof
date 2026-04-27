class MenuItemSize {
  final String name;
  final int priceCentsDelta;

  const MenuItemSize({required this.name, required this.priceCentsDelta});

  factory MenuItemSize.fromJson(Map<String, dynamic> json) {
    return MenuItemSize(
      name: json['name'] as String,
      priceCentsDelta: (json['price_cents_delta'] as num?)?.toInt() ?? 0,
    );
  }
}

// Standard size set used as a fallback when the server doesn't ship sizes
// (e.g. older servers). Keep in sync with kof_server/src/utils/menuSizes.js.
const kDefaultSizes = <MenuItemSize>[
  MenuItemSize(name: 'Small', priceCentsDelta: -50),
  MenuItemSize(name: 'Medium', priceCentsDelta: 0),
  MenuItemSize(name: 'Large', priceCentsDelta: 50),
  MenuItemSize(name: 'Xtra Large', priceCentsDelta: 100),
];

const kDefaultSizeName = 'Medium';
