import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/menu_item.dart';
import '../models/order.dart';

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  Future<Map<String, dynamic>> walkin() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/walkin'))
        .timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) throw Exception('Server not reachable');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

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
    required String fulfillmentType,
    required List<Map<String, dynamic>> items,
    String tableLabel = '',
    String tableToken = '',
    String customerLabel = '',
    String note = '',
  }) async {
    final body = <String, dynamic>{
      'fulfillment_type': fulfillmentType,
      'note': note,
      'items': items,
    };
    if (fulfillmentType == 'counter_pickup') {
      body['customer_label'] = customerLabel;
    } else {
      body['table_label'] = tableLabel;
      body['table_token'] = tableToken;
    }
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/orders'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
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
