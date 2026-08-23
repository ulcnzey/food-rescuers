import '../enums/user_role.dart';

class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.role,
    this.canSell = false,
    this.avatarId = 0,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String fullName;

  /// Eski rol alani. Artik yonlendirmede kullanilmiyor,
  /// geriye donuk uyumluluk icin duruyor.
  final UserRole role;

  /// Kullanici ilan verebiliyor mu. Isletme olusturunca true olur.
  final bool canSell;

  /// Secili vektorel avatar. Dosya yuklenmez, uygulama icinde cizilir.
  final int avatarId;

  final String? phone;
  final String? avatarUrl;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      fullName: (map['full_name'] as String?) ?? '',
      role: (map['role'] as String?) == 'business'
          ? UserRole.business
          : UserRole.consumer,
      canSell: (map['can_sell'] as bool?) ?? false,
      avatarId: (map['avatar_id'] as int?) ?? 0,
      phone: map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'avatar_id': avatarId,
      };
}