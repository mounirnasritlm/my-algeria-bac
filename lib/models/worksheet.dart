class Worksheet {
  final String id;

  final String title;

  final String subjectId;

  final String? lessonId;

  final String sourceId;

  final String fileUrl;

  final String fileType;

  final bool verified;

  const Worksheet({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.lessonId,
    required this.sourceId,
    required this.fileUrl,
    required this.fileType,
    required this.verified,
  });

  factory Worksheet.fromJson(Map<String, dynamic> json) {
    return Worksheet(
      id: json['id'] as String,
      title: json['title'] as String,
      subjectId: json['subjectId'] as String,
      lessonId: json['lessonId'] as String?,
      sourceId: json['sourceId'] as String,
      fileUrl: json['fileUrl'] as String,
      fileType: json['fileType'] as String,
      verified: json['verified'] as bool? ?? false,
    );
  }
}
