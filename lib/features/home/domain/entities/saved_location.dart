import 'package:flutter/material.dart';

class SavedLocation {
  const SavedLocation({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    this.address,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String? address;
  final double latitude;
  final double longitude;
  final bool isDefault;

  /// Etikete gore ikon secer: Ev, Is, Okul...
  IconData get icon {
    final l = label.toLowerCase();
    if (l.contains('ev')) return Icons.home_rounded;
    if (l.contains('iş') || l.contains('is')) return Icons.work_rounded;
    if (l.contains('okul')) return Icons.school_rounded;
    return Icons.place_rounded;
  }

  factory SavedLocation.fromMap(Map<String, dynamic> map) {
    return SavedLocation(
      id: map['id'] as String,
      label: (map['label'] as String?) ?? '',
      address: map['address'] as String?,
      latitude: (map['lat'] as num?)?.toDouble() ?? 0,
      longitude: (map['lng'] as num?)?.toDouble() ?? 0,
      isDefault: (map['is_default'] as bool?) ?? false,
    );
  }
}