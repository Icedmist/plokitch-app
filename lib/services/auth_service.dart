import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'data_cache_service.dart';

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

    // Try to extract session token from Set-Cookie and response body.
    String? token = _extractSessionToken(res.headers['set-cookie'] ?? res.headers['Set-Cookie']);

    if (token == null) {
      try {
        final body = json.decode(res.body);
        if (body is Map<String, dynamic>) {
          token = _extractSessionTokenFromBody(body);
        }
      } catch (_) {}
    }

    if (token == null || token.isEmpty) {
      throw Exception('Sign in succeeded but no session token was returned.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, token);
    // attempt to fetch and persist profile role immediately
    try {
      final profile = await getProfile();
      final role = profile?['role'] as String?;
      if (role != null) await prefs.setString(_roleKey, role);
    } catch (_) {}
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_sessionKey);
    try {
      final uri = _uri('/api/auth/sign-out');
      await http.post(uri, headers: _buildHeaders(token));
    } catch (_) {}
    await prefs.remove(_sessionKey);
    await prefs.remove(_roleKey);
    DataCacheService.clear();
  }

  static Future<Map<String, dynamic>?> getProfile({bool forceRefresh = false}) async {
    const cacheKey = 'user_profile';
    if (!forceRefresh) {
      final cached = DataCacheService.get(cacheKey);
      if (cached != null) return cached;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_sessionKey);
    if (token == null || token.isEmpty) {
      DataCacheService.invalidate(cacheKey);
      return null;
    }

    final uri = _uri('/api/users/me');
    final res = await http.get(uri, headers: _buildHeaders(token));
    if (res.statusCode != 200) {
      if (res.statusCode == 401 || res.statusCode == 403) {
        await prefs.remove(_sessionKey);
        await prefs.remove(_roleKey);
        DataCacheService.invalidate(cacheKey);
      }
      return null;
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data != null) {
      final role = data['role'] as String?;
      if (role != null) {
        await prefs.setString(_roleKey, role);
      }
      DataCacheService.set(cacheKey, data);
    }
    return data;
  }

  static void invalidateProfile() {
    DataCacheService.invalidate('user_profile');
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
        DataCacheService.invalidate('user_profile');
        return false;
      }
      // parse new token from Set-Cookie or body
      String? newToken = _extractSessionToken(res.headers['set-cookie'] ?? res.headers['Set-Cookie']);
      if (newToken == null) {
        try {
          final body = json.decode(res.body);
          if (body is Map<String, dynamic>) {
            newToken = _extractSessionTokenFromBody(body);
          }
        } catch (_) {}
      }
      if (newToken != null && newToken.isNotEmpty) {
        await prefs.setString(_sessionKey, newToken);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Map<String, String> _buildHeaders(String? token) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      headers['x-better-auth-session'] = token;
      headers['Cookie'] = 'plokitch.session_token=$token';
    }
    return headers;
  }

  static String? _extractSessionToken(String? cookieHeader) {
    if (cookieHeader == null || cookieHeader.isEmpty) return null;
    final match = RegExp(r'plokitch\.session_token=([^;\s]+)').firstMatch(cookieHeader);
    return match?.group(1);
  }

  static String? _extractSessionTokenFromBody(Map<String, dynamic> body) {
    String? token;

    token = body['token'] as String?;
    token ??= body['accessToken'] as String?;
    token ??= body['access_token'] as String?;
    token ??= body['sessionToken'] as String?;
    token ??= body['session'] is Map<String, dynamic> ? (body['session']['token'] as String?) : null;

    if (token == null && body['data'] is Map<String, dynamic>) {
      final data = body['data'] as Map<String, dynamic>;
      token = data['token'] as String?;
      token ??= data['accessToken'] as String?;
      token ??= data['access_token'] as String?;
      token ??= data['sessionToken'] as String?;
      token ??= data['session'] is Map<String, dynamic> ? (data['session']['token'] as String?) : null;
    }

    return token;
  }

  static Future<Map<String, String>> authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_sessionKey);
    final headers = _buildHeaders(token);

    final role = prefs.getString(_roleKey);
    if (role == 'admin') {
      final overrideRole = prefs.getString('admin_active_role');
      if (overrideRole != null && overrideRole.isNotEmpty) {
        headers['x-admin-active-role'] = overrideRole;
        // Append to Cookie header to prevent CORS preflight blocking on production servers
        if (token != null && token.isNotEmpty) {
          headers['Cookie'] = 'plokitch.session_token=$token; admin_active_role=$overrideRole';
        } else {
          headers['Cookie'] = 'admin_active_role=$overrideRole';
        }
      }
    }
    return headers;
  }

  /// Send reset password email.
  static Future<void> forgotPassword(String email) async {
    final uri = _uri('/api/auth/forget-password');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email.trim(),
        'redirectTo': '/reset-password',
      }),
    );

    if (res.statusCode >= 400) {
      String message = 'Failed to send reset link';
      try {
        final body = json.decode(res.body);
        message = body['error'] ?? body['message'] ?? message;
      } catch (_) {}
      throw Exception(message);
    }
  }
}
