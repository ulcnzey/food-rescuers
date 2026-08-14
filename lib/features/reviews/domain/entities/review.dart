class Review {
  const Review({
    required this.id,
    required this.rating,
    required this.userName,
    required this.createdAt,
    this.comment,
    this.reply,
    this.repliedAt,
  });

  final String id;
  final int rating;
  final String userName;
  final String? comment;

  /// Isletme sahibinin cevabi.
  final String? reply;
  final DateTime? repliedAt;
  final DateTime createdAt;

  bool get hasReply => reply != null && reply!.trim().isNotEmpty;

  /// Gizlilik icin sadece bas harfler: "Zeynep U."
  String get maskedName {
    final parts = userName.trim().split(' ');
    if (parts.length < 2) return parts.first;
    return '${parts.first} ${parts.last[0]}.';
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays == 0) return 'Bugün';
    if (diff.inDays == 1) return 'Dün';
    if (diff.inDays < 30) return '${diff.inDays} gün önce';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30} ay önce';
    return '${diff.inDays ~/ 365} yıl önce';
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] as String,
      rating: (map['rating'] as int?) ?? 0,
      comment: map['comment'] as String?,
      reply: map['reply'] as String?,
      repliedAt: map['replied_at'] == null
          ? null
          : DateTime.parse(map['replied_at'] as String).toLocal(),
      userName: (map['user_name'] as String?) ?? 'Kullanıcı',
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}

/// Puan dagilimi: kac kisi kac yildiz vermis.
class RatingBreakdown {
  const RatingBreakdown(this.counts);

  /// {5: 12, 4: 3, 3: 1, 2: 0, 1: 0}
  final Map<int, int> counts;

  int get total => counts.values.fold(0, (a, b) => a + b);

  double get average {
    if (total == 0) return 0;
    final sum = counts.entries
        .fold<int>(0, (acc, e) => acc + e.key * e.value);
    return sum / total;
  }

  /// Belirli yildizin toplam icindeki orani (0-1).
  double ratioOf(int star) => total == 0 ? 0 : (counts[star] ?? 0) / total;

  factory RatingBreakdown.fromRows(List<dynamic> rows) {
    final map = {for (var i = 1; i <= 5; i++) i: 0};

    for (final row in rows) {
      final m = row as Map<String, dynamic>;
      map[m['rating'] as int] = m['count'] as int;
    }

    return RatingBreakdown(map);
  }
}