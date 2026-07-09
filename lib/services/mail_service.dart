import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class MailService {
  MailService._();

  static final String _baseUrl = dotenv.env['VITE_API_URL'] ?? dotenv.env['PLOKITCH_API_URL'] ?? 'http://localhost:4000';

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static Future<Map<String, String>> _headers() async {
    final base = await AuthService.authHeaders();
    base.putIfAbsent('Content-Type', () => 'application/json');
    return base;
  }

  /// Sends an email notification via the backend.
  /// [type] can be 'order_placed', 'order_accepted', 'order_processing', 'order_ready', 'order_delivered'.
  static Future<void> sendOrderNotification({
    required String orderId,
    required String recipientEmail,
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final uri = _uri('/api/notifications/email');
      final res = await http.post(
        uri,
        headers: await _headers(),
        body: json.encode({
          'orderId': orderId,
          'email': recipientEmail,
          'type': type,
          'metadata': metadata ?? {},
        }),
      );

      if (res.statusCode >= 400) {
        // Silently log or handle error - we don't want to crash the app if mail fails
        print('Mail notification failed: ${res.body}');
      }
    } catch (e) {
      print('Error sending mail notification: $e');
    }
  }

  /// Convenience method for when an order is placed.
  static Future<void> notifyOrderPlaced(String orderId, String userEmail, String vendorEmail) async {
    // Notify customer
    await sendOrderNotification(
      orderId: orderId,
      recipientEmail: userEmail,
      type: 'order_placed',
    );
    // Notify vendor
    await sendOrderNotification(
      orderId: orderId,
      recipientEmail: vendorEmail,
      type: 'new_order_received',
    );
  }
}
