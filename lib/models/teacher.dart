import 'source.dart';

class Teacher {
  final String id;

  final String name;

  final List<String> subjectIds;

  final List<String> topics;

  final String? description;

  final List<TeacherPlatform> platforms;

  final ContentSource source;

  const Teacher({
    required this.id,
    required this.name,
    this.subjectIds = const [],
    this.topics = const [],
    this.description,
    this.platforms = const [],
    required this.source,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    final platforms = <TeacherPlatform>[
      for (final platform in json['platforms'] as List? ?? const [])
        TeacherPlatform.fromJson(platform as Map<String, dynamic>),
    ];

    return Teacher(
      id: json['id'] as String,
      name: json['name'] as String,
      subjectIds: (json['subjectIds'] as List? ?? const []).cast<String>(),
      topics: (json['topics'] as List? ?? const []).cast<String>(),
      description: json['description'] as String?,
      platforms: platforms,
      source: ContentSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }
}

class TeacherPlatform {
  final String platform;

  final String? handle;

  final String? url;

  final bool verified;

  const TeacherPlatform({
    required this.platform,
    this.handle,
    this.url,
    this.verified = false,
  });

  factory TeacherPlatform.fromJson(Map<String, dynamic> json) {
    return TeacherPlatform(
      platform: json['platform'] as String,
      handle: json['handle'] as String?,
      url: json['url'] as String?,
      verified: json['verified'] as bool? ?? false,
    );
  }
}
