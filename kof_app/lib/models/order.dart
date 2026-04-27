class Order {
  final int id;
  final int orderNumber;
  String status;
  String paymentStatus;
  final String fulfillmentType;
  final String tableLabel;
  final String customerLabel;
  final String note;
  final List<OrderItem> items;
  final String createdAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.fulfillmentType,
    required this.tableLabel,
    required this.customerLabel,
    required this.note,
    required this.items,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      orderNumber: json['order_number'] as int,
      status: json['status'] as String,
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      fulfillmentType: json['fulfillment_type'] as String? ?? 'table',
      tableLabel: json['table_label'] as String? ?? '',
      customerLabel: json['customer_label'] as String? ?? '',
      note: json['note'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  bool get isActive =>
      status == 'new' || status == 'making' || status == 'ready';

  int get totalCents =>
      items.fold(0, (sum, item) => sum + item.lineTotalCents);
}

class OrderItem {
  final int menuItemId;
  final String name;
  final int qty;
  final int lineTotalCents;
  final List<dynamic> chosenModifiers;

  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.qty,
    required this.lineTotalCents,
    this.chosenModifiers = const [],
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menu_item_id'] as int,
      // Server returns the joined item name as `item_name`. Keep `name` as a
      // fallback for older payloads.
      name: (json['item_name'] as String?) ??
          (json['name'] as String?) ??
          '',
      qty: json['qty'] as int,
      lineTotalCents: json['line_total_cents'] as int,
      chosenModifiers: (json['chosen_modifiers'] as List<dynamic>?) ?? const [],
    );
  }
}
