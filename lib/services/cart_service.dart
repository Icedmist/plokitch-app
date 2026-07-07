import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CartService {
  static const _key = 'PLOKITCH_CART_V1';

  CartService._();

  static Future<List<Map<String, dynamic>>> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = json.decode(raw) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> saveCart(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(items));
  }

  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
