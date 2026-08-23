import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/business.dart';
import '../domain/entities/business_stats.dart';

class BusinessRepository {
  BusinessRepository(this._client);

  final SupabaseClient _client;

  /// Giris yapmis kullanicinin isletmesi. Yoksa null.
  Future<Business?> fetchMyBusiness() async {
    final rows = await _client.rpc('my_business') as List<dynamic>;
    if (rows.isEmpty) return null;
    return Business.fromMap(rows.first as Map<String, dynamic>);
  }

  /// Isletme panelinin gunluk ozeti.
  Future<BusinessStats> fetchStats() async {
    final rows = await _client.rpc('business_dashboard_stats') as List<dynamic>;
    if (rows.isEmpty) return const BusinessStats();
    return BusinessStats.fromMap(rows.first as Map<String, dynamic>);
  }

  /// Yeni isletme olusturur, olusan kaydin id'sini doner.
  Future<String> createBusiness({
    required String name,
    required BusinessCategory category,
    required double latitude,
    required double longitude,
    required List<int> openDays,
    ProviderType providerType = ProviderType.business,
    String? description,
    String? address,
    String? phone,
    String? opensAt,
    String? closesAt,
    String? logoUrl,
  }) async {
    final id = await _client.rpc(
      'create_business',
      params: {
        'p_name': name,
        'p_category': category.name,
        'p_lat': latitude,
        'p_lng': longitude,
        'p_provider_type': providerType.name,
        'p_description': description,
        'p_address': address,
        'p_phone': phone,
        'p_opens_at': opensAt,
        'p_closes_at': closesAt,
        'p_open_days': openDays,
        'p_logo_url': logoUrl,
      },
    );

    return id as String;
  }

  /// Isletme bilgilerini kismi gunceller.
  /// Null gonderilen alanlar veritabaninda COALESCE ile korunur.
  Future<void> updateMyBusiness({
    String? name,
    BusinessCategory? category,
    String? description,
    String? address,
    String? phone,
    String? opensAt,
    String? closesAt,
    List<int>? openDays,
    String? logoUrl,
    double? latitude,
    double? longitude,
  }) async {
    await _client.rpc(
      'update_my_business',
      params: {
        'p_name': name,
        'p_category': category?.name,
        'p_description': description,
        'p_address': address,
        'p_phone': phone,
        'p_opens_at': opensAt,
        'p_closes_at': closesAt,
        'p_open_days': openDays,
        'p_logo_url': logoUrl,
        'p_lat': latitude,
        'p_lng': longitude,
      },
    );
  }
}