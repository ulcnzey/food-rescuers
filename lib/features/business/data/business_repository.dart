import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/business.dart';

class BusinessRepository {
  BusinessRepository(this._client);

  final SupabaseClient _client;

  /// Giris yapmis kullanicinin isletmesi. Yoksa null.
  Future<Business?> fetchMyBusiness() async {
    final rows = await _client.rpc('my_business') as List<dynamic>;
    if (rows.isEmpty) return null;
    return Business.fromMap(rows.first as Map<String, dynamic>);
  }

  /// Yeni isletme olusturur, olusan kaydin id'sini doner.
  Future<String> createBusiness({
    required String name,
    required BusinessCategory category,
    required double latitude,
    required double longitude,
    String? description,
    String? address,
    String? phone,
    String? opensAt,
    String? closesAt,
  }) async {
    final id = await _client.rpc(
      'create_business',
      params: {
        'p_name': name,
        'p_category': category.name,
        'p_lat': latitude,
        'p_lng': longitude,
        'p_description': description,
        'p_address': address,
        'p_phone': phone,
        'p_opens_at': opensAt,
        'p_closes_at': closesAt,
      },
    );

    return id as String;
  }

  /// Mevcut isletme bilgilerini gunceller.
  Future<void> updateBusiness({
    required String businessId,
    String? name,
    String? description,
    String? address,
    String? phone,
    String? opensAt,
    String? closesAt,
  }) async {
    final changes = <String, dynamic>{};
    if (name != null) changes['name'] = name;
    if (description != null) changes['description'] = description;
    if (address != null) changes['address'] = address;
    if (phone != null) changes['phone'] = phone;
    if (opensAt != null) changes['opens_at'] = opensAt;
    if (closesAt != null) changes['closes_at'] = closesAt;

    if (changes.isEmpty) return;

    await _client.from('businesses').update(changes).eq('id', businessId);
  }
}