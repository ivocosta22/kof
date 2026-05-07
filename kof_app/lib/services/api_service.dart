import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/shop_discount.dart';

/// Normalised API error codes that screens map to localized messages via
/// `localizedApiError`.
enum ApiErrorCode {
  serverNotReachable,
  failedLoadMenu,
  failedPlaceOrder,
  orderNotFound,
  failedLoadDiscounts,
  unknown,
}

class ApiException implements Exception {
  final ApiErrorCode code;
  final String? rawMessage;
  const ApiException(this.code, [this.rawMessage]);

  @override
  String toString() => rawMessage ?? code.name;
}

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  Future<Map<String, dynamic>> walkin() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/walkin'))
        .timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) {
      throw const ApiException(ApiErrorCode.serverNotReachable);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getInfo() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/info'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw const ApiException(ApiErrorCode.serverNotReachable);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<MenuItem>> getMenu() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/menu'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw const ApiException(ApiErrorCode.failedLoadMenu);
    }
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
    String discountCode = '',
  }) async {
    final body = <String, dynamic>{
      'fulfillment_type': fulfillmentType,
      'note': note,
      'items': items,
    };
    if (discountCode.isNotEmpty) {
      body['discount_code'] = discountCode;
    }
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
      throw ApiException(
        ApiErrorCode.failedPlaceOrder,
        data['error'] as String?,
      );
    }
    return Order.fromJson(data['order'] as Map<String, dynamic>);
  }

  Future<Order> getOrder(int id) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/orders/$id'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw const ApiException(ApiErrorCode.orderNotFound);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Order.fromJson(data['order'] as Map<String, dynamic>);
  }

  // Public list of currently-valid discounts at this shop. Returns an empty
  // list if the shop has none active or hasn't enabled discounts at all.
  Future<List<ShopDiscount>> getDiscounts() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/discounts'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw const ApiException(ApiErrorCode.failedLoadDiscounts);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['discounts'] as List<dynamic>? ?? [])
        .map((e) => ShopDiscount.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
