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

  /// Sends an email notification via the backend compatibility endpoint.
  ///
  /// The backend expects: { action: string, payload: {...} }
  ///
  /// Supported actions:
  ///   - 'welcome'
  ///   - 'order_receipt'
  ///   - 'new_order_vendor'
  ///   - 'order_delivering'
  ///   - 'order_completed'
  ///   - 'order_cancelled'
  static Future<void> sendAction({
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final uri = _uri('/api/notifications/email');
      final res = await http.post(
        uri,
        headers: await _headers(),
        body: json.encode({
          'action': action,
          'payload': payload,
        }),
      );

      if (res.statusCode >= 400) {
        print('[MailService] Email failed ($action): ${res.body}');
      }
    } catch (e) {
      print('[MailService] Error sending email ($action): $e');
    }
  }

  /// Convenience: order placed → notify customer + vendor.
  static Future<void> notifyOrderPlaced({
    required String orderId,
    required String customerName,
    required String customerEmail,
    required String vendorName,
    required String vendorEmail,
    required Map<String, dynamic> order,
  }) async {
    await Future.wait([
      sendAction(
        action: 'order_receipt',
        payload: {
          'order': order,
          'customerName': customerName,
          'customerEmail': customerEmail,
          'vendorName': vendorName,
        },
      ),
      sendAction(
        action: 'new_order_vendor',
        payload: {
          'order': order,
          'vendorEmail': vendorEmail,
          'vendorName': vendorName,
          'customerName': customerName,
        },
      ),
    ]);
  }

  /// Rider assigned → notify customer.
  static Future<void> notifyRiderAssigned({
    required Map<String, dynamic> order,
    required String customerName,
    required String customerEmail,
    required String riderName,
  }) async {
    await sendAction(
      action: 'order_assigned',
      payload: {
        'order': order,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'riderName': riderName,
      },
    );
  }

  /// Order picked up / in transit → notify customer.
  static Future<void> notifyOrderDelivering({
    required Map<String, dynamic> order,
    required String customerName,
    required String customerEmail,
  }) async {
    await sendAction(
      action: 'order_delivering',
      payload: {
        'order': order,
        'customerName': customerName,
        'customerEmail': customerEmail,
      },
    );
  }

  /// Order delivered → notify customer + vendor + rider.
  static Future<void> notifyOrderDelivered({
    required Map<String, dynamic> order,
    required String customerName,
    required String customerEmail,
    required String vendorName,
    required String vendorEmail,
    String? riderName,
    String? riderEmail,
  }) async {
    await sendAction(
      action: 'order_completed',
      payload: {
        'order': order,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'vendorName': vendorName,
        'vendorEmail': vendorEmail,
        if (riderName != null) 'riderName': riderName,
        if (riderEmail != null) 'riderEmail': riderEmail,
      },
    );
  }

  /// New review posted → notify vendor.
  static Future<void> notifyNewReview({
    required String vendorName,
    required String vendorEmail,
    required String customerName,
    required double rating,
    required String comment,
  }) async {
    await sendAction(
      action: 'new_review_vendor',
      payload: {
        'vendorName': vendorName,
        'vendorEmail': vendorEmail,
        'customerName': customerName,
        'rating': rating,
        'comment': comment,
      },
    );
  }

  /// Order cancelled → notify customer + vendor + rider.
  static Future<void> notifyOrderCancelled({
    required Map<String, dynamic> order,
    required String vendorName,
    required String vendorEmail,
    String? customerName,
    String? customerEmail,
    String? riderName,
    String? riderEmail,
  }) async {
    await sendAction(
      action: 'order_cancelled',
      payload: {
        'order': order,
        'vendorName': vendorName,
        'vendorEmail': vendorEmail,
        if (customerName != null) 'customerName': customerName,
        if (customerEmail != null) 'customerEmail': customerEmail,
        if (riderName != null) 'riderName': riderName,
        if (riderEmail != null) 'riderEmail': riderEmail,
      },
    );
  }
}
