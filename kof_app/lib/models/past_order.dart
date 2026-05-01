import 'order.dart';

class PastOrder {
  final String shopName;
  final String serverUrl;
  final int orderId;
  final int orderNumber;
  String status;
  final String tableLabel;
  final List<OrderItem> items;
  final String createdAt;
  // Cached so the cards display the correct total even if the items list is
  // empty — e.g. when older entries were saved before the server began
  // returning items on order creation.
  final int totalCents;
  final String discountCode;
  final int discountAmountCents;

  PastOrder({
    required this.shopName,
    required this.serverUrl,
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.tableLabel,
    required this.items,
    required this.createdAt,
    int? totalCents,
    this.discountCode = '',
    this.discountAmountCents = 0,
  }) : totalCents = totalCents ??
            (() {
              final subtotal =
                  items.fold(0, (s, i) => s + i.lineTotalCents);
              final t = subtotal - discountAmountCents;
              return t < 0 ? 0 : t;
            })();

  bool get isActive =>
      status == 'new' || status == 'making' || status == 'ready';

  factory PastOrder.fromOrder(
    Order order, {
    required String shopName,
    required String serverUrl,
  }) =>
      PastOrder(
        shopName: shopName,
        serverUrl: serverUrl,
        orderId: order.id,
        orderNumber: order.orderNumber,
        status: order.status,
        tableLabel: order.tableLabel,
        items: order.items,
        createdAt: order.createdAt,
        discountCode: order.discountCode,
        discountAmountCents: order.discountAmountCents,
      );

  Map<String, dynamic> toJson() => {
        'shopName': shopName,
        'serverUrl': serverUrl,
        'orderId': orderId,
        'orderNumber': orderNumber,
        'status': status,
        'tableLabel': tableLabel,
        'items': items
            .map((i) => {
                  'menu_item_id': i.menuItemId,
                  'name': i.name,
                  'qty': i.qty,
                  'line_total_cents': i.lineTotalCents,
                })
            .toList(),
        'createdAt': createdAt,
        'totalCents': totalCents,
        'discountCode': discountCode,
        'discountAmountCents': discountAmountCents,
      };

  factory PastOrder.fromJson(Map<String, dynamic> json) {
    final items = ((json['items'] as List?) ?? [])
        .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return PastOrder(
      shopName: json['shopName'] as String? ?? '',
      serverUrl: json['serverUrl'] as String? ?? '',
      orderId: json['orderId'] as int,
      orderNumber: json['orderNumber'] as int,
      status: json['status'] as String,
      tableLabel: json['tableLabel'] as String? ?? '',
      items: items,
      createdAt: json['createdAt'] as String? ?? '',
      totalCents: json['totalCents'] as int?,
      discountCode: json['discountCode'] as String? ?? '',
      discountAmountCents: (json['discountAmountCents'] as int?) ?? 0,
    );
  }
}
