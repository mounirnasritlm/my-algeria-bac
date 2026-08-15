import 'source.dart';

class Lesson {
  final String id;
  final String subjectId;
  final String title;
  final String description;
  final List<String> conceptIds;
  final int estimatedMinutes;
  final ContentSource source;

  const Lesson({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.conceptIds,
    required this.estimatedMinutes,
    required this.source,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      conceptIds: (json['conceptIds'] as List? ?? const []).cast<String>(),
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 0,
      source: ContentSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }
}
