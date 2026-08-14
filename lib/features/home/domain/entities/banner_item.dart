import 'package:flutter/material.dart';

enum BannerLinkType { business, offer, url, none }

class BannerItem {
  const BannerItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.linkType = BannerLinkType.none,
    this.linkValue,
    this.bgColor = const Color(0xFF0F4C42),
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final BannerLinkType linkType;
  final String? linkValue;
  final Color bgColor;

  factory BannerItem.fromMap(Map<String, dynamic> map) {
    return BannerItem(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? '',
      subtitle: map['subtitle'] as String?,
      imageUrl: map['image_url'] as String?,
      linkType: switch (map['link_type'] as String?) {
        'business' => BannerLinkType.business,
        'offer' => BannerLinkType.offer,
        'url' => BannerLinkType.url,
        _ => BannerLinkType.none,
      },
      linkValue: map['link_value'] as String?,
      bgColor: _parseColor(map['bg_color'] as String?),
    );
  }

  /// "#0F4C42" -> Color
  static Color _parseColor(String? hex) {
    if (hex == null || !hex.startsWith('#') || hex.length != 7) {
      return const Color(0xFF0F4C42);
    }
    final value = int.tryParse(hex.substring(1), radix: 16);
    return value == null ? const Color(0xFF0F4C42) : Color(0xFF000000 | value);
  }
}