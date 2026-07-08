import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();

  static final String _baseUrl = dotenv.env['VITE_API_URL'] ?? dotenv.env['PLOKITCH_API_URL'] ?? 'http://localhost:4000';
  static const String _sessionKey = 'PLOKITCH_SESSION_TOKEN';
  static const String _roleKey = 'PLOKITCH_USER_ROLE';

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  /// Sign up using email + password.
  static Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    final uri = _uri('/api/auth/sign-up/email');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email.trim(),
        'password': password,
        'role': role,
        'phone': phone,
      }),
    );

    if (res.statusCode >= 400) {
      String message = 'Sign up failed';
      try {
        final body = json.decode(res.body);
        message = body['error'] ?? body['message'] ?? message;
      } catch (_) {}
      throw Exception(message);
    }

    // Usually sign up also returns a session or we auto sign in
    await signIn(email, password);
  }

  /// Sign in using email + password. Stores session token (from Set-Cookie) in SharedPreferences.
  static Future<void> signIn(String email, String password) async {
    final uri = _uri('/api/auth/sign-in/email');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email.trim(), 'password': password}),
    );

    if (res.statusCode >= 400) {
      String message = 'Sign in failed';
      try {
        final body = json.decode(res.body);
        message = body['error'] ?? body['message'] ?? message;
      } catch (_) {}
      throw Exception(message);
    }

    // Try to extract session token from Set-Cookie
    String? setCookie = res.headers['set-cookie'] ?? res.headers['Set-Cookie'];
    String? token;
    if (setCookie != null) {
      final match = RegExp(r'plokitch\.session_token=([^;]+)').firstMatch(setCookie);
      if (match != null) token = match.group(1);
    }

    // Also check response body for session token fallback
    if (token == null) {
      try {
        final body = json.decode(res.body) as Map<String, dynamic>;
        token = body['session']?['token'] ?? body['token'] as String?;
      } catch (_) {}
    }

    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, token);
      // attempt to fetch and persist profile role immediately
      try {
        final profile = await getProfile();
        final role = profile?['role'] as String?;
        if (role != null) await prefs.setString(_roleKey, role);
      } catch (_) {}
    }
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_sessionKey);
    try {
      final uri = _uri('/api/auth/sign-out');
      await http.post(uri, headers: _buildHeaders(token));
    } catch (_) {}
    await prefs.remove(_sessionKey);
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_sessionKey);
    final uri = _uri('/api/users/me');
    final res = await http.get(uri, headers: _buildHeaders(token));
    if (res.statusCode != 200) return null;
    final body = json.decode(res.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data != null) {
      final role = data['role'] as String?;
      if (role != null) {
        await prefs.setString(_roleKey, role);
      }
    }
    return data;
  }

  /// Returns stored role if available.
  static Future<String?> storedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  /// Attempt to refresh session token using backend refresh endpoint.
  /// If refresh fails, clears stored session.
  static Future<bool> tryRefreshSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_sessionKey);
    if (token == null) return false;
    try {
      final uri = _uri('/api/auth/refresh');
      final res = await http.post(uri, headers: _buildHeaders(token));
      if (res.statusCode != 200) {
        await prefs.remove(_sessionKey);
        await prefs.remove(_roleKey);
        return false;
      }
      // parse new token from Set-Cookie or body
      String? setCookie = res.headers['set-cookie'] ?? res.headers['Set-Cookie'];
      String? newToken;
      if (setCookie != null) {
        final match = RegExp(r'plokitch\.session_token=([^;]+)').firstMatch(setCookie);
        if (match != null) newToken = match.group(1);
      }
      if (newToken == null) {
        try {
          final body = json.decode(res.body) as Map<String, dynamic>;
          newToken = body['session']?['token'] ?? body['token'] as String?;
        } catch (_) {}
      }
      if (newToken != null) {
        await prefs.setString(_sessionKey, newToken);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Map<String, String> _buildHeaders(String? token) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['x-better-auth-session'] = token;
      headers['Cookie'] = 'plokitch.session_token=$token';
    }
    return headers;
  }

  static Future<Map<String, String>> authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_sessionKey);
    return _buildHeaders(token);
  }
}
