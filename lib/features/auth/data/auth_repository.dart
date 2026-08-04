import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/profile.dart';
import '../domain/enums/user_role.dart';

/// Supabase ile konusan tek yer. Ekranlar buraya bakar,
/// Supabase'in kendisini hic gormez.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Kayit olur. Profil kaydini veritabanindaki trigger otomatik olusturur.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Giris yapmis kullanicinin profilini ceker.
  Future<Profile?> fetchProfile() async {
    final id = currentUserId;
    if (id == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromMap(data);
  }

  /// Rol secimi ekraninda cagrilir.
  Future<void> updateRole(UserRole role) async {
    final id = currentUserId;
    if (id == null) throw StateError('Oturum yok');

    await _client.from('profiles').update({'role': role.name}).eq('id', id);
  }

  Future<void> updateProfile({String? fullName, String? phone}) async {
    final id = currentUserId;
    if (id == null) throw StateError('Oturum yok');

    final changes = <String, dynamic>{};
    if (fullName != null) changes['full_name'] = fullName;
    if (phone != null) changes['phone'] = phone;
    if (changes.isEmpty) return;

    await _client.from('profiles').update(changes).eq('id', id);
  }
}