class VideoResource {
  final String id;

  final String title;

  final String teacherId;

  final String subjectId;

  final String? lessonId;

  final String platform;

  final String videoId;

  final String url;

  final int? durationSeconds;

  final bool verified;

  const VideoResource({
    required this.id,
    required this.title,
    required this.teacherId,
    required this.subjectId,
    required this.lessonId,
    required this.platform,
    required this.videoId,
    required this.url,
    required this.durationSeconds,
    required this.verified,
  });

  factory VideoResource.fromJson(Map<String, dynamic> json) {
    return VideoResource(
      id: json['id'] as String,
      title: json['title'] as String,
      teacherId: json['teacherId'] as String,
      subjectId: json['subjectId'] as String,
      lessonId: json['lessonId'] as String?,
      platform: json['platform'] as String,
      videoId: json['videoId'] as String,
      url: json['url'] as String,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      verified: json['verified'] as bool? ?? false,
    );
  }
}
