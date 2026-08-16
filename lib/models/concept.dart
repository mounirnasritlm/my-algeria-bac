class Concept {
  final String id;

  final String name;

  final String summary;

  final String lessonId;

  final String sourceId;

  const Concept({
    required this.id,
    required this.name,
    required this.summary,
    required this.lessonId,
    required this.sourceId,
  });

  factory Concept.fromJson(Map<String, dynamic> json) {
    return Concept(
      id: json['id'] as String,
      name: json['name'] as String,
      summary: json['summary'] as String? ?? '',
      lessonId: json['lessonId'] as String,
      sourceId: json['sourceId'] as String,
    );
  }
}
