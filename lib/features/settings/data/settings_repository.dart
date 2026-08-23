import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/static_page.dart';

class SettingsRepository {
  SettingsRepository(this._client);

  final SupabaseClient _client;

  Future<StaticPage?> fetchPage(String slug) async {
    final rows = await _client.rpc(
      'get_static_page',
      params: {'p_slug': slug},
    ) as List<dynamic>;

    if (rows.isEmpty) return null;
    return StaticPage.fromMap(rows.first as Map<String, dynamic>);
  }

  Future<List<FaqItem>> fetchFaq() async {
    final rows = await _client.rpc('get_faq') as List<dynamic>;
    return rows
        .map((e) => FaqItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MonthlyImpact>> fetchMonthlyImpact() async {
    final rows = await _client.rpc('my_impact_monthly') as List<dynamic>;
    return rows
        .map((e) => MonthlyImpact.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateAvatar(int avatarId) async {
    await _client.rpc('update_avatar', params: {'p_avatar_id': avatarId});
  }

  Future<void> updateFullName(String fullName) async {
    await _client.rpc(
      'update_full_name',
      params: {'p_full_name': fullName.trim()},
    );
  }

  Future<void> createTicket({
    required String type,
    required String subject,
    required String message,
    String? email,
  }) async {
    await _client.rpc(
      'create_support_ticket',
      params: {
        'p_type': type,
        'p_subject': subject,
        'p_message': message,
        'p_email': email,
      },
    );
  }
}