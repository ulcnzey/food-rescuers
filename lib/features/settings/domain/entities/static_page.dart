class StaticPage {
  const StaticPage({
    required this.slug,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  final String slug;
  final String title;
  final String content;
  final DateTime updatedAt;

  factory StaticPage.fromMap(Map<String, dynamic> map) {
    return StaticPage(
      slug: map['slug'] as String,
      title: (map['title'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    );
  }
}

class FaqItem {
  const FaqItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
  });

  final String id;
  final String category;
  final String question;
  final String answer;

  String get categoryLabel => switch (category) {
        'general' => 'Genel',
        'reservation' => 'Rezervasyon',
        'business' => 'İşletmeler',
        _ => 'Diğer',
      };

  factory FaqItem.fromMap(Map<String, dynamic> map) {
    return FaqItem(
      id: map['id'] as String,
      category: (map['category'] as String?) ?? 'general',
      question: (map['question'] as String?) ?? '',
      answer: (map['answer'] as String?) ?? '',
    );
  }
}

/// Aylik etki dokumu.
class MonthlyImpact {
  const MonthlyImpact({
    required this.monthStart,
    required this.mealsSaved,
    required this.originalValue,
    required this.paidValue,
    required this.moneySaved,
    required this.co2Kg,
  });

  final DateTime monthStart;
  final int mealsSaved;
  final double originalValue;
  final double paidValue;
  final double moneySaved;
  final double co2Kg;

  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  String get monthLabel =>
      '${_months[monthStart.month - 1]} ${monthStart.year}';

  factory MonthlyImpact.fromMap(Map<String, dynamic> map) {
    return MonthlyImpact(
      monthStart: DateTime.parse(map['month_start'] as String),
      mealsSaved: (map['meals_saved'] as int?) ?? 0,
      originalValue: (map['original_value'] as num?)?.toDouble() ?? 0,
      paidValue: (map['paid_value'] as num?)?.toDouble() ?? 0,
      moneySaved: (map['money_saved'] as num?)?.toDouble() ?? 0,
      co2Kg: (map['co2_kg'] as num?)?.toDouble() ?? 0,
    );
  }
}