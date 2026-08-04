import '../enums/user_role.dart';

class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;

  bool get isBusiness => role == UserRole.business;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      fullName: (map['full_name'] as String?) ?? '',
      role: (map['role'] as String?) == 'business'
          ? UserRole.business
          : UserRole.consumer,
      phone: map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'full_name': fullName,
        'role': role.name,
        'phone': phone,
        'avatar_url': avatarUrl,
      };
}