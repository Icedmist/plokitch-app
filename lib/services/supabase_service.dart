import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseClient get client => Supabase.instance.client;

  Future<AuthResponse> signInWithEmail(String email, String password) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) {
    return client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() => client.auth.signOut();

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final resp = await client.from('profiles').select().eq('id', userId).maybeSingle();
      return resp;
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }
}
