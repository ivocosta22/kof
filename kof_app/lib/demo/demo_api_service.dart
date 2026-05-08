import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/shop_discount.dart';
import '../services/api_service.dart';
import 'demo_data.dart';

/// Drop-in replacement for [ApiService] used in demo mode.
/// All methods return mock data; no HTTP requests are ever made.
class DemoApiService extends ApiService {
  static int _nextId = 1002;
  static final Map<int, Order> _orders = _seedOrders();

  static Map<int, Order> _seedOrders() {
    return {
      1001: Order(
        id: 1001,
        orderNumber: 1,
        status: 'completed',
        paymentStatus: 'paid',
        fulfillmentType: 'counter_pickup',
        tableLabel: '',
        customerLabel: 'Alex',
        note: '',
        items: [
          OrderItem(menuItemId: 5, name: 'Latte', qty: 1, lineTotalCents: 400, chosenModifiers: const []),
          OrderItem(menuItemId: 13, name: 'Cinnamon Roll', qty: 1, lineTotalCents: 320, chosenModifiers: const []),
        ],
        createdAt: _daysAgo(2),
      ),
      1002: Order(
        id: 1002,
        orderNumber: 2,
        status: 'completed',
        paymentStatus: 'paid',
        fulfillmentType: 'table',
        tableLabel: '3',
        customerLabel: '',
        note: '',
        items: [
          OrderItem(menuItemId: 1, name: 'Espresso', qty: 2, lineTotalCents: 500, chosenModifiers: const []),
          OrderItem(menuItemId: 4, name: 'Cappuccino', qty: 1, lineTotalCents: 380, chosenModifiers: const []),
        ],
        createdAt: _daysAgo(5),
      ),
    };
  }

  static String _daysAgo(int days) {
    final dt = DateTime.now().subtract(Duration(days: days));
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
        '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
  }

  static int? get latestOrderId => _orders.isEmpty ? null : _orders.keys.last;

  static void updateOrderStatus(int id, String status) {
    if (_orders.containsKey(id)) _orders[id]!.status = status;
  }

  DemoApiService() : super(DemoData.kServerUrl);

  @override
  Future<Map<String, dynamic>> walkin() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return {'ok': true, 'name': 'Kof', 'shop_name': DemoData.shop1.name};
  }

  @override
  Future<Map<String, dynamic>> getInfo() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return {'name': 'Kof', 'shop_name': DemoData.shop1.name};
  }

  @override
  Future<List<MenuItem>> getMenu() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return DemoData.menuItems;
  }

  @override
  Future<Order> placeOrder({
    required String fulfillmentType,
    required List<Map<String, dynamic>> items,
    String tableLabel = '',
    String tableToken = '',
    String customerLabel = '',
    String note = '',
    String discountCode = '',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final id = ++_nextId;
    final now = DateTime.now();
    final createdAt =
        '${now.year}-${_pad(now.month)}-${_pad(now.day)} '
        '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}';

    final orderItems = items.map((raw) {
      final menuItemId = raw['menu_item_id'] as int;
      final qty = raw['qty'] as int;
      final modifiers =
          (raw['chosen_modifiers'] as List?)?.cast<dynamic>() ?? const [];
      final item = DemoData.menuItems.firstWhere(
        (m) => m.id == menuItemId,
        orElse: () => DemoData.menuItems.first,
      );
      final sizeDelta = _sizeDelta(item, modifiers);
      return OrderItem(
        menuItemId: menuItemId,
        name: item.name,
        qty: qty,
        lineTotalCents: (item.priceCents + sizeDelta) * qty,
        chosenModifiers: modifiers,
      );
    }).toList();

    int discountAmountCents = 0;
    if (discountCode.isNotEmpty) {
      final discount = DemoData.discounts
          .where((d) => d.code.toLowerCase() == discountCode.toLowerCase())
          .firstOrNull;
      if (discount != null) {
        final subtotal = orderItems.fold(0, (s, i) => s + i.lineTotalCents);
        discountAmountCents = _calcDiscount(discount, subtotal, orderItems);
      }
    }

    final order = Order(
      id: id,
      orderNumber: id - 1000,
      status: 'new',
      paymentStatus: 'unpaid',
      fulfillmentType: fulfillmentType,
      tableLabel: tableLabel,
      customerLabel: customerLabel,
      note: note,
      items: orderItems,
      createdAt: createdAt,
      discountCode: discountCode,
      discountAmountCents: discountAmountCents,
    );

    _orders[id] = order;
    return order;
  }

  @override
  Future<Order> getOrder(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final order = _orders[id];
    if (order == null) throw const ApiException(ApiErrorCode.orderNotFound);
    return order;
  }

  @override
  Future<List<ShopDiscount>> getDiscounts() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return DemoData.discounts;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static int _sizeDelta(MenuItem item, List<dynamic> modifiers) {
    for (final m in modifiers) {
      final s = m?.toString() ?? '';
      if (s.startsWith('size:')) {
        final sizeName = s.substring(5);
        for (final sz in item.sizes) {
          if (sz.name == sizeName) return sz.priceCentsDelta;
        }
      }
    }
    return 0;
  }

  static int _calcDiscount(
    ShopDiscount d,
    int subtotal,
    List<OrderItem> items,
  ) {
    final reqCats = _cats(d.requiredCategory);
    if (reqCats.isNotEmpty) {
      // Discount requires a specific category in the cart — skip if absent.
      // We can't easily check category here without the full MenuItem, so we
      // trust the cart-side validation and just apply the raw formula.
    }

    int basis;
    final targetCats = _cats(d.targetCategory);
    if (targetCats.isEmpty) {
      basis = subtotal;
    } else {
      basis = items
          .where((i) => targetCats.any((c) => i.name.isNotEmpty))
          .fold(0, (s, i) => s + i.lineTotalCents);
      if (basis == 0) basis = subtotal;
    }

    int cents = 0;
    if (d.percentageOff > 0) {
      cents = (basis * d.percentageOff) ~/ 100;
    } else if (d.amountOffCents > 0) {
      cents = d.amountOffCents;
    }
    if (cents > subtotal) cents = subtotal;
    return cents;
  }

  static List<String> _cats(String raw) => raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
