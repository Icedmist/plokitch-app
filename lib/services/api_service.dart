import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'data_cache_service.dart';
import '../models/vendor_model.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';

class ApiService {
  ApiService._();

  static final String _baseUrl = dotenv.env['VITE_API_URL'] ?? dotenv.env['PLOKITCH_API_URL'] ?? 'http://localhost:4000';
  
  static String get baseUrl => _baseUrl;

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static Future<Map<String, String>> _headers() async {
    final base = await AuthService.authHeaders();
    // ensure content-type is present
    base.putIfAbsent('Content-Type', () => 'application/json');
    return base;
  }

  static Future<List<dynamic>> fetchVendors({int limit = 50, int offset = 0, bool forceRefresh = false}) async {
    const cacheKey = 'vendors_list';
    if (!forceRefresh) {
      final cached = DataCacheService.get(cacheKey);
      if (cached != null) return cached;
    }

    final uri = _uri('/api/vendors?limit=$limit&offset=$offset');
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to fetch vendors');
    final body = json.decode(res.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>;
    final result = list.map((e) => VendorModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    
    DataCacheService.set(cacheKey, result);
    return result;
  }

  static Future<Map<String, dynamic>> fetchVendor(String idOrSlug, {bool forceRefresh = false}) async {
    final cacheKey = 'vendor_$idOrSlug';
    if (!forceRefresh) {
      final cached = DataCacheService.get(cacheKey);
      if (cached != null) return cached;
    }

    final uri = _uri('/api/vendors/$idOrSlug');
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to fetch vendor');
    final body = json.decode(res.body) as Map<String, dynamic>;
    final result = body['data'] as Map<String, dynamic>;
    
    DataCacheService.set(cacheKey, result);
    return result;
  }

  
  static Future<Map<String, dynamic>> fetchMyVendor() async {
    final uri = _uri('/api/vendors/me');
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch user kitchen profile: ${res.body}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createVendor(Map<String, dynamic> payload) async {
    final uri = _uri('/api/vendors');
    final res = await http.post(uri, headers: await _headers(), body: json.encode(payload));
    if (res.statusCode >= 400) {
      throw Exception('Failed to create kitchen: ${res.body}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    
    DataCacheService.invalidate('vendors_list');
    DataCacheService.invalidate('user_profile');
    
    return body['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateVendor(String vendorId, Map<String, dynamic> payload) async {
    final uri = _uri('/api/vendors/$vendorId');
    final res = await http.patch(uri, headers: await _headers(), body: json.encode(payload));
    if (res.statusCode >= 400) {
      throw Exception('Failed to update vendor: ${res.body}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    
    DataCacheService.invalidate('vendor_$vendorId');
    DataCacheService.invalidate('vendors_list');
    
    return body['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> fetchVendorMenu(String vendorId, {bool forceRefresh = false}) async {
    final cacheKey = 'menu_$vendorId';
    if (!forceRefresh) {
      final cached = DataCacheService.get(cacheKey);
      if (cached != null) return cached;
    }

    final uri = _uri('/api/vendors/$vendorId/menu');
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to fetch menu');
    final body = json.decode(res.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>;
    final result = list.map((e) => MenuItemModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    
    DataCacheService.set(cacheKey, result);
    return result;
  }

  static Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> payload) async {
    final uri = _uri('/api/orders');
    final res = await http.post(uri, headers: await _headers(), body: json.encode(payload));
    if (res.statusCode >= 400) {
      throw Exception('Failed to place order: ${res.body}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    
    DataCacheService.invalidate('orders_list');
    
    return body['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> addMenuItem(String vendorId, Map<String, dynamic> payload) async {
    final uri = _uri('/api/vendors/$vendorId/menu');
    final res = await http.post(uri, headers: await _headers(), body: json.encode(payload));
    if (res.statusCode >= 400) {
      throw Exception('Failed to add menu item: ${res.body}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    DataCacheService.invalidate('menu_$vendorId');
    return body['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateMenuItem(String vendorId, String itemId, Map<String, dynamic> payload) async {
    final uri = _uri('/api/vendors/$vendorId/menu/$itemId');
    final res = await http.patch(uri, headers: await _headers(), body: json.encode(payload));
    if (res.statusCode >= 400) {
      throw Exception('Failed to update menu item: ${res.body}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    DataCacheService.invalidate('menu_$vendorId');
    return body['data'] as Map<String, dynamic>;
  }

  static Future<void> deleteMenuItem(String vendorId, String itemId) async {
    final uri = _uri('/api/vendors/$vendorId/menu/$itemId');
    final res = await http.delete(uri, headers: await _headers());
    if (res.statusCode >= 400) {
      throw Exception('Failed to delete menu item: ${res.body}');
    }
    DataCacheService.invalidate('menu_$vendorId');
  }

  static Future<void> saveUserLocation(Map<String, dynamic> payload) async {
    final uri = _uri('/api/users/me');
    final res = await http.patch(uri, headers: await _headers(), body: json.encode(payload));
    if (res.statusCode >= 400) {
      throw Exception('Failed to save location: ${res.body}');
    }
    DataCacheService.invalidate('user_profile');
  }

  static Future<void> updateUserProfile(Map<String, dynamic> payload) async {
    final uri = _uri('/api/users/me');
    final res = await http.patch(uri, headers: await _headers(), body: json.encode(payload));
    if (res.statusCode >= 400) {
      throw Exception('Failed to update profile: ${res.body}');
    }
    DataCacheService.invalidate('user_profile');
  }

  static Future<void> addNotification({
    required String title,
    required String body,
    String type = 'system',
  }) async {
    try {
      final uri = _uri('/api/notifications');
      final res = await http.post(
        uri,
        headers: await _headers(),
        body: json.encode({
          'title': title,
          'message': body,
          'type': type,
        }),
      );
      if (res.statusCode >= 400) {
        throw Exception('Failed to add notification: ${res.body}');
      }
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> fetchNotifications({int limit = 50, bool unreadOnly = false}) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      if (unreadOnly) 'unread': 'true',
    };
    final queryString = Uri(queryParameters: queryParams).query;
    final uri = _uri('/api/notifications?$queryString');
    
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to fetch notifications');
    return json.decode(res.body) as Map<String, dynamic>;
  }

  static Future<void> markNotificationAsRead(String id) async {
    final uri = _uri('/api/notifications/$id/read');
    final res = await http.patch(uri, headers: await _headers(), body: '{}');
    if (res.statusCode >= 400) throw Exception('Failed to mark notification read');
  }

  static Future<void> markAllNotificationsAsRead() async {
    final uri = _uri('/api/notifications/read-all');
    final res = await http.post(uri, headers: await _headers(), body: '{}');
    if (res.statusCode >= 400) throw Exception('Failed to mark all notifications read');
  }

  static Future<List<OrderModel>> fetchOrders({int limit = 50, int offset = 0, String? customerId, String? vendorId, bool forceRefresh = false}) async {
    final cacheKey = 'orders_list_${customerId ?? ""}_${vendorId ?? ""}';
    if (!forceRefresh) {
      final cached = DataCacheService.get(cacheKey);
      if (cached != null) return cached;
    }

    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (customerId != null) queryParams['customerId'] = customerId;
    if (vendorId != null) queryParams['vendorId'] = vendorId;

    final queryString = Uri(queryParameters: queryParams).query;
    final uri = _uri('/api/orders?$queryString');
    
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to fetch orders');
    final body = json.decode(res.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>;
    final result = list
        .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    
    DataCacheService.set(cacheKey, result);
    return result;
  }

  static Future<OrderModel> fetchOrder(String orderId) async {
    final uri = _uri('/api/orders/$orderId');
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to fetch order');
    final body = json.decode(res.body) as Map<String, dynamic>;
    return OrderModel.fromJson(Map<String, dynamic>.from(body['data'] as Map));
  }

  static Future<OrderModel> updateOrderStatus(String orderId, String status) async {
    final uri = _uri('/api/orders/$orderId/status');
    final res = await http.patch(uri, headers: await _headers(), body: json.encode({'status': status}));
    if (res.statusCode != 200) throw Exception('Failed to update order status');
    final body = json.decode(res.body) as Map<String, dynamic>;
    return OrderModel.fromJson(Map<String, dynamic>.from(body['data'] as Map));
  }
}
