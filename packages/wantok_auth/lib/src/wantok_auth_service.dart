import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wantok_api/wantok_api.dart';

class WantokAuthService {
  const WantokAuthService();

  SupabaseClient get _client => WantokBackend.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (fullName != null && fullName.trim().isNotEmpty)
          'full_name': fullName.trim(),
      },
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<Set<String>> loadRoles() async {
    final user = currentUser;
    if (user == null) return <String>{};

    final rows = await _client
        .from('user_roles')
        .select('role_code, expires_at')
        .eq('user_id', user.id);

    final now = DateTime.now().toUtc();
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((row) {
          final expiresAt = row['expires_at'] as String?;
          if (expiresAt == null) return true;
          return DateTime.parse(expiresAt).toUtc().isAfter(now);
        })
        .map((row) => row['role_code'] as String)
        .toSet();
  }
}
