import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._();

  static final String _baseUrl = dotenv.env['PLOKITCH_API_URL'] ?? 'http://localhost:4000';

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('PLOKITCH_SESSION_TOKEN');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['x-better-auth-session'] = token;
      headers['Cookie'] = 'plotkitch.session_token=$token';
    }
    return headers;
  }

  static Future<List<dynamic>> fetchVendors({int limit = 50, int offset = 0}) async {
    final uri = _uri('/api/vendors?limit=$limit&offset=$offset');
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to fetch vendors');
    final body = json.decode(res.body) as Map<String, dynamic>;
    return body['data'] as List<dynamic>;
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
    return body['data'] as List<dynamic>;
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

  static Future<List<dynamic>> fetchOrders({int limit = 50, int offset = 0}) async {
    final uri = _uri('/api/orders?limit=$limit&offset=$offset');
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to fetch orders');
    final body = json.decode(res.body) as Map<String, dynamic>;
    return body['data'] as List<dynamic>;
  }
}
