import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/vendor_model.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';

class ApiService {
  ApiService._();

  static final String _baseUrl = dotenv.env['VITE_API_URL'] ?? dotenv.env['PLOKITCH_API_URL'] ?? 'http://localhost:4000';

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static Future<Map<String, String>> _headers() async {
    final base = await AuthService.authHeaders();
    // ensure content-type is present
    base.putIfAbsent('Content-Type', () => 'application/json');
    return base;
  }

  static Future<List<dynamic>> fetchVendors({int limit = 50, int offset = 0}) async {
    final uri = _uri('/api/vendors?limit=$limit&offset=$offset');
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to fetch vendors');
    final body = json.decode(res.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>;
    return list.map((e) => VendorModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<Map<String, dynamic>> fetchVendor(String idOrSlug) async {
    final uri = _uri('/api/vendors/$idOrSlug');
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to fetch vendor');
    final body = json.decode(res.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> fetchVendorMenu(String vendorId) async {
    final uri = _uri('/api/vendors/$vendorId/menu');
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to fetch menu');
    final body = json.decode(res.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>;
    return list.map((e) => MenuItemModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> payload) async {
    final uri = _uri('/api/orders');
    final res = await http.post(uri, headers: await _headers(), body: json.encode(payload));
    if (res.statusCode >= 400) {
      throw Exception('Failed to place order: ${res.body}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  static Future<void> saveUserLocation(Map<String, dynamic> payload) async {
    final uri = _uri('/api/users/me');
    final res = await http.patch(uri, headers: await _headers(), body: json.encode(payload));
    if (res.statusCode >= 400) {
      throw Exception('Failed to save location: ${res.body}');
    }
  }

  static Future<void> updateUserProfile(Map<String, dynamic> payload) async {
    final uri = _uri('/api/users/me');
    final res = await http.patch(uri, headers: await _headers(), body: json.encode(payload));
    if (res.statusCode >= 400) {
      throw Exception('Failed to update profile: ${res.body}');
    }
  }

  static Future<List<OrderModel>> fetchOrders({int limit = 50, int offset = 0}) async {
    final uri = _uri('/api/orders?limit=$limit&offset=$offset');
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to fetch orders');
    final body = json.decode(res.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>;
    return list
        .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
