import 'source.dart';

class Concept {
  final String id;

  final String name;

  final String summary;

  final String lessonId;

  final ContentSource source;

  const Concept({
    required this.id,
    required this.name,
    required this.summary,
    required this.lessonId,
    required this.source,
  });

  factory Concept.fromJson(Map<String, dynamic> json) {
    return Concept(
      id: json['id'] as String,
      name: json['name'] as String,
      summary: json['summary'] as String? ?? '',
      lessonId: json['lessonId'] as String,
      source: ContentSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }
}
