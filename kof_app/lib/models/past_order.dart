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

  PastOrder({
    required this.shopName,
    required this.serverUrl,
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.tableLabel,
    required this.items,
    required this.createdAt,
  });

  int get totalCents => items.fold(0, (s, i) => s + i.lineTotalCents);
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
      };

  factory PastOrder.fromJson(Map<String, dynamic> json) => PastOrder(
        shopName: json['shopName'] as String? ?? '',
        serverUrl: json['serverUrl'] as String? ?? '',
        orderId: json['orderId'] as int,
        orderNumber: json['orderNumber'] as int,
        status: json['status'] as String,
        tableLabel: json['tableLabel'] as String? ?? '',
        items: ((json['items'] as List?) ?? [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: json['createdAt'] as String? ?? '',
      );
}
