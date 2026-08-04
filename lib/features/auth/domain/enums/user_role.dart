enum UserRole {
  consumer,
  business;

  String get displayName {
    switch (this) {
      case UserRole.consumer:
        return 'Bireysel Kullanıcı';
      case UserRole.business:
        return 'İşletme';
    }
  }
}
