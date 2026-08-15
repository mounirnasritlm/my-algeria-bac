import 'source.dart';

class Video {
  final String id;

  final String title;

  final String? teacherId;

  final String platform;

  final String? url;

  final String subjectId;

  final List<String> conceptIds;

  final int? durationMinutes;

  final String? language;

  final ContentSource source;

  const Video({
    required this.id,
    required this.title,
    this.teacherId,
    required this.platform,
    this.url,
    required this.subjectId,
    this.conceptIds = const [],
    this.durationMinutes,
    this.language,
    required this.source,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] as String,
      title: json['title'] as String,
      teacherId: json['teacherId'] as String?,
      platform: json['platform'] as String,
      url: json['url'] as String?,
      subjectId: json['subjectId'] as String,
      conceptIds: (json['conceptIds'] as List? ?? const []).cast<String>(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      language: json['language'] as String?,
      source: ContentSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }
}
