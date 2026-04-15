class Order {
  final int id;
  final int orderNumber;
  String status;
  final String fulfillmentType;
  final String tableLabel;
  final List<OrderItem> items;
  final String createdAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.fulfillmentType,
    required this.tableLabel,
    required this.items,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      orderNumber: json['order_number'] as int,
      status: json['status'] as String,
      fulfillmentType: json['fulfillment_type'] as String? ?? 'table',
      tableLabel: json['table_label'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  bool get isActive =>
      status == 'new' || status == 'making' || status == 'ready';
}

class OrderItem {
  final int menuItemId;
  final String name;
  final int qty;
  final int lineTotalCents;

  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.qty,
    required this.lineTotalCents,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menu_item_id'] as int,
      name: json['name'] as String? ?? '',
      qty: json['qty'] as int,
      lineTotalCents: json['line_total_cents'] as int,
    );
  }
}
