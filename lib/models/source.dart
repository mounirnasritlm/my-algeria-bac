class ContentSource {
  final String sourceType;

  final String? sourceName;

  final String? sourceYear;

  final String? sourceUrl;

  final String? sourcePage;

  final bool verified;

  const ContentSource({
    required this.sourceType,
    required this.verified,
    this.sourceName,
    this.sourceYear,
    this.sourceUrl,
    this.sourcePage,
  });

  factory ContentSource.fromJson(Map<String, dynamic> json) {
    return ContentSource(
      sourceType: json['sourceType'] as String,
      verified: json['verified'] as bool? ?? false,
      sourceName: json['sourceName'] as String?,
      sourceYear: json['sourceYear'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      sourcePage: json['sourcePage'] as String?,
    );
  }

  static const ContentSource requiresVerification = ContentSource(
    sourceType: 'CONTENT_REQUIRES_VERIFICATION',
    verified: false,
  );

  static const ContentSource demoContent = ContentSource(
    sourceType: 'demo_content',
    verified: false,
  );
}
