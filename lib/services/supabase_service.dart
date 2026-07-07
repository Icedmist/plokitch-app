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
    final resp = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single()
        .execute();
    if (resp.error != null) throw resp.error!;
    return resp.data as Map<String, dynamic>?;
  }
}
