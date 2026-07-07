import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._();

  static final String _baseUrl = dotenv.env['PLOKITCH_API_URL'] ?? 'http://localhost:4000';

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static Future<List<dynamic>> fetchVendors({int limit = 50, int offset = 0}) async {
    final uri = _uri('/api/vendors?limit=$limit&offset=$offset');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to fetch vendors');
    final body = json.decode(res.body) as Map<String, dynamic>;
    return body['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> fetchVendor(String idOrSlug) async {
    final uri = _uri('/api/vendors/$idOrSlug');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to fetch vendor');
    final body = json.decode(res.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> fetchVendorMenu(String vendorId) async {
    final uri = _uri('/api/vendors/$vendorId/menu');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to fetch menu');
    final body = json.decode(res.body) as Map<String, dynamic>;
    return body['data'] as List<dynamic>;
  }
}
