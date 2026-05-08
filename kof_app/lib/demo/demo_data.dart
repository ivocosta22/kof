import '../models/menu_item.dart';
import '../models/menu_item_size.dart';
import '../models/order.dart';
import '../models/past_order.dart';
import '../models/shop.dart';
import '../models/shop_discount.dart';
import '../models/user.dart';

/// Static mock data for demo mode. No Firebase, no backend server required.
abstract final class DemoData {
  // ── Server URL sentinel ────────────────────────────────────────────────────
  static const kServerUrl = 'demo://kof';
  static const kServer2Url = 'demo://kof-porto';

  // ── Demo user ──────────────────────────────────────────────────────────────
  static const demoUser = User(
    id: 'demo-user',
    name: 'Alex',
    email: 'demo@kof.example.com',
    emailVerified: true,
  );

  // ── Shops ──────────────────────────────────────────────────────────────────
  static final shop1 = Shop(
    id: 'demo-shop-1',
    name: "Helsinki's Finest",
    description:
        'Specialty coffee and homemade pastries in the heart of Helsinki. '
        'Our beans are sourced from single-origin farms and roasted in-house.',
    address: 'Aleksanterinkatu 12, Helsinki, Finland',
    latitude: 60.1699,
    longitude: 24.9384,
    tags: const ['Specialty Coffee', 'Pastries', 'Cozy', 'Wi-Fi'],
    rating: 4.7,
    ratingCount: 124,
    phone: '+358 9 123 4567',
    country: 'Finland',
    serverUrl: kServerUrl,
  );

  static final shop2 = Shop(
    id: 'demo-shop-2',
    name: 'The Daily Grind',
    description:
        "Porto's favourite third-wave coffee shop. Great espresso, "
        'vegan pastries, and a sun-drenched terrace overlooking the river.',
    address: 'Rua de Santa Catarina 42, Porto, Portugal',
    latitude: 41.1496,
    longitude: -8.6109,
    tags: const ['Specialty Coffee', 'Vegan-friendly', 'Terrace'],
    rating: 4.5,
    ratingCount: 89,
    phone: '+351 22 123 4567',
    country: 'Portugal',
    serverUrl: kServer2Url,
  );

  static List<Shop> get allShops => [shop1, shop2];

  // ── Menu items (Helsinki's Finest) ────────────────────────────────────────
  static const menuItems = <MenuItem>[
    // Espresso
    MenuItem(
      id: 1,
      name: 'Espresso',
      description: 'A rich, full-bodied shot of our house blend.',
      priceCents: 250,
      availability: 'available',
      category: 'Espresso',
    ),
    MenuItem(
      id: 3,
      name: 'Americano',
      description: 'Espresso diluted with hot water — clean and smooth.',
      priceCents: 300,
      availability: 'available',
      category: 'Espresso',
    ),
    // Hot Drinks
    MenuItem(
      id: 4,
      name: 'Cappuccino',
      description: 'Equal parts espresso, steamed milk, and velvety foam.',
      priceCents: 380,
      availability: 'available',
      category: 'Hot Drinks',
      hasSizes: true,
      sizes: [
        MenuItemSize(name: 'Small', priceCentsDelta: -50),
        MenuItemSize(name: 'Medium', priceCentsDelta: 0),
        MenuItemSize(name: 'Large', priceCentsDelta: 50),
      ],
    ),
    MenuItem(
      id: 5,
      name: 'Latte',
      description:
          'Espresso with silky steamed milk. Add oat, almond or soy.',
      priceCents: 400,
      availability: 'available',
      category: 'Hot Drinks',
      hasSizes: true,
      sizes: [
        MenuItemSize(name: 'Small', priceCentsDelta: -50),
        MenuItemSize(name: 'Medium', priceCentsDelta: 0),
        MenuItemSize(name: 'Large', priceCentsDelta: 50),
      ],
    ),
    MenuItem(
      id: 7,
      name: 'Hot Chocolate',
      description: 'Rich Belgian chocolate with steamed whole milk.',
      priceCents: 350,
      availability: 'available',
      category: 'Hot Drinks',
    ),
    // Cold Drinks
    MenuItem(
      id: 8,
      name: 'Iced Americano',
      description: 'Double espresso poured over ice. Refreshing.',
      priceCents: 350,
      availability: 'available',
      category: 'Cold Drinks',
    ),
    MenuItem(
      id: 9,
      name: 'Cold Brew',
      description: 'Steeped for 18 hours — silky smooth with low acidity.',
      priceCents: 450,
      availability: 'low',
      category: 'Cold Drinks',
    ),
    MenuItem(
      id: 10,
      name: 'Matcha Latte',
      description: 'Ceremonial-grade matcha with oat milk.',
      priceCents: 500,
      availability: 'available',
      category: 'Cold Drinks',
    ),
    // Pastries
    MenuItem(
      id: 11,
      name: 'Chocolate Muffin',
      description: 'Baked fresh daily. Rich dark chocolate with a soft centre.',
      priceCents: 250,
      availability: 'available',
      category: 'Pastries',
    ),
    MenuItem(
      id: 12,
      name: 'Croissant',
      description: 'Buttery and flaky. Best enjoyed still warm.',
      priceCents: 280,
      availability: 'available',
      category: 'Pastries',
    ),
    MenuItem(
      id: 13,
      name: 'Cinnamon Roll',
      description: 'Classic Nordic cardamom bun with icing.',
      priceCents: 320,
      availability: 'available',
      category: 'Pastries',
    ),
    // Food
    MenuItem(
      id: 14,
      name: 'Avocado Toast',
      description: 'Sourdough, smashed avocado, chilli flakes, poached egg.',
      priceCents: 890,
      availability: 'unavailable',
      category: 'Food',
    ),
  ];

  // ── Discounts ──────────────────────────────────────────────────────────────
  static const discounts = <ShopDiscount>[
    ShopDiscount(
      id: 1,
      title: 'Pastry + Drink Deal',
      description:
          'Buy any pastry and get one espresso or hot/cold drink free.',
      percentageOff: 100,
      amountOffCents: 0,
      code: 'MUFFIN',
      validFrom: '2026-01-01',
      validUntil: '2026-12-31',
      isActive: true,
      requiredCategory: 'Pastries',
      targetCategory: 'Espresso,Hot Drinks,Cold Drinks',
      targetQty: 1,
    ),
    ShopDiscount(
      id: 2,
      title: 'Summer Special',
      description: '25% off your entire order. No minimum spend.',
      percentageOff: 25,
      amountOffCents: 0,
      code: 'SUMMER25',
      validFrom: '2026-01-01',
      validUntil: '2026-12-31',
      isActive: true,
    ),
  ];

  // ── Past orders (pre-seeded history for demo user) ────────────────────────
  static List<PastOrder> get demoPastOrders => [
        PastOrder(
          shopName: shop1.name,
          serverUrl: kServerUrl,
          orderId: 1001,
          orderNumber: 1,
          status: 'completed',
          tableLabel: '',
          items: [
            OrderItem(menuItemId: 5, name: 'Latte', qty: 1, lineTotalCents: 400, chosenModifiers: []),
            OrderItem(menuItemId: 13, name: 'Cinnamon Roll', qty: 1, lineTotalCents: 320, chosenModifiers: []),
          ],
          createdAt: _daysAgo(2),
          totalCents: 720,
        ),
        PastOrder(
          shopName: shop1.name,
          serverUrl: kServerUrl,
          orderId: 1002,
          orderNumber: 2,
          status: 'completed',
          tableLabel: '3',
          items: [
            OrderItem(menuItemId: 1, name: 'Espresso', qty: 2, lineTotalCents: 500, chosenModifiers: []),
            OrderItem(menuItemId: 4, name: 'Cappuccino', qty: 1, lineTotalCents: 380, chosenModifiers: []),
          ],
          createdAt: _daysAgo(5),
          totalCents: 880,
        ),
      ];

  static String _daysAgo(int days) {
    final dt = DateTime.now().subtract(Duration(days: days));
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
        '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  // ── Sample notifications ───────────────────────────────────────────────────
  static final sampleNotifications = <Map<String, dynamic>>[
    {
      'id': 'demo-notif-1',
      'title': 'Weekend Special!',
      'body': 'Half-price croissants today. Come in before noon and mention Kof!',
      'shopId': 'demo-shop-1',
      'minutesAgo': 90,
    },
    {
      'id': 'demo-notif-2',
      'title': 'New Seasonal Blend',
      'body': 'Our Autumn Spice Latte is now available. Try it today!',
      'shopId': 'demo-shop-1',
      'minutesAgo': 1440,
    },
  ];
}
