import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PaystackService {
  PaystackService._();

  static const String _defaultPublicKey = 'pk_test_540d47025deaa96503ec8deb7b87dbd12b882329';
  static const String _defaultSecretKey = 'sk_test_8828fc0213dc7a9e6426f84e56709f565a34d033';

  static String get publicKey =>
      dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? _defaultPublicKey;

  static String get secretKey =>
      dotenv.env['PAYSTACK_SECRET_KEY'] ?? _defaultSecretKey;

  static const String _baseUrl = 'https://api.paystack.co';

  /// Generates a unique transaction reference for Paystack
  static String generateReference([String prefix = 'plokitch_pay']) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomStr = Random().nextInt(999999).toString().padLeft(6, '0');
    return '${prefix}_${timestamp}_$randomStr';
  }

  /// Detects card brand based on card number prefix
  static String detectCardBrand(String cardNumber) {
    final clean = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('4')) return 'Visa';
    if (RegExp(r'^(5[1-5]|222[1-9]|22[3-9]|2[3-6]|27[0-1]|2720)').hasMatch(clean)) {
      return 'Mastercard';
    }
    if (RegExp(r'^(506[0-1]|507[8-9]|6500)').hasMatch(clean)) {
      return 'Verve';
    }
    return 'Card';
  }

  /// Validates card number using the Luhn algorithm
  static bool validateCardNumber(String cardNumber) {
    final clean = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 13 || clean.length > 19) return false;
    int sum = 0;
    bool isSecond = false;
    for (int i = clean.length - 1; i >= 0; i--) {
      int digit = int.parse(clean[i]);
      if (isSecond) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      isSecond = !isSecond;
    }
    return sum % 10 == 0;
  }

  /// Initializes a Paystack transaction via the REST API
  static Future<Map<String, dynamic>> initializeTransaction({
    required String email,
    required double amountInNaira,
    String? reference,
    Map<String, dynamic>? metadata,
  }) async {
    final ref = reference ?? generateReference();
    final amountInKobo = (amountInNaira * 100).round();

    final url = Uri.parse('$_baseUrl/transaction/initialize');
    final headers = {
      'Authorization': 'Bearer $secretKey',
      'Content-Type': 'application/json',
    };
    final body = json.encode({
      'email': email,
      'amount': amountInKobo,
      'reference': ref,
      'currency': 'NGN',
      if (metadata != null) 'metadata': metadata,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && jsonResponse['status'] == true) {
        final data = jsonResponse['data'] as Map<String, dynamic>;
        return {
          'success': true,
          'authorization_url': data['authorization_url'],
          'access_code': data['access_code'],
          'reference': data['reference'],
        };
      } else {
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Failed to initialize Paystack transaction',
          'reference': ref,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error while contacting Paystack: $e',
        'reference': ref,
      };
    }
  }

  /// Verifies a Paystack transaction status via the REST API
  static Future<Map<String, dynamic>> verifyTransaction(String reference) async {
    final url = Uri.parse('$_baseUrl/transaction/verify/$reference');
    final headers = {
      'Authorization': 'Bearer $secretKey',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && jsonResponse['status'] == true) {
        final data = jsonResponse['data'] as Map<String, dynamic>;
        final isSuccess = data['status'] == 'success';
        return {
          'success': isSuccess,
          'status': data['status'],
          'amount': (data['amount'] as num? ?? 0) / 100.0,
          'gateway_response': data['gateway_response'] ?? 'Transaction processed',
          'paid_at': data['paid_at'],
          'channel': data['channel'],
          'reference': data['reference'],
          'customer': data['customer'],
          'authorization': data['authorization'],
        };
      } else {
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Verification failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error verifying Paystack transaction: $e',
      };
    }
  }
}
