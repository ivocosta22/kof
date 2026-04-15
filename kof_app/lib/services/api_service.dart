import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/menu_item.dart';
import '../models/order.dart';

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  Future<Map<String, dynamic>> getInfo() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/info'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('Server not reachable');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<MenuItem>> getMenu() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/menu'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('Failed to load menu');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['items'] as List<dynamic>)
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Order> placeOrder({
    required String tableLabel,
    required String tableToken,
    required List<Map<String, dynamic>> items,
    String note = '',
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/orders'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'fulfillment_type': 'table',
            'table_label': tableLabel,
            'table_token': tableToken,
            'note': note,
            'items': items,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw Exception(data['error'] ?? 'Failed to place order');
    }
    return Order.fromJson(data['order'] as Map<String, dynamic>);
  }

  Future<Order> getOrder(int id) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/orders/$id'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw Exception('Order not found');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Order.fromJson(data['order'] as Map<String, dynamic>);
  }
}
