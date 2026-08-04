class LegalDocument {
  final String id;
  final String docType; // 'terms' or 'privacy'
  final int version;
  final String title;
  final String content;
  final DateTime effectiveAt;

  const LegalDocument({
    required this.id,
    required this.docType,
    required this.version,
    required this.title,
    required this.content,
    required this.effectiveAt,
  });
}
