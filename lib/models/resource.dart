import 'source.dart';

enum ResourceType { book, worksheet, website, studyGuide }

class Resource {
  final String id;

  final ResourceType type;

  final String title;

  final String? authorCreator;

  final String? publisher;

  final String? language;

  final String? url;

  final String? description;

  final List<String> subjectIds;

  final String? level;

  final ContentSource source;

  const Resource({
    required this.id,
    required this.type,
    required this.title,
    this.authorCreator,
    this.publisher,
    this.language,
    this.url,
    this.description,
    this.subjectIds = const [],
    this.level,
    required this.source,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'] as String,
      type: _resourceTypeFromString(json['type'] as String?),
      title: json['title'] as String,
      authorCreator: json['authorCreator'] as String?,
      publisher: json['publisher'] as String?,
      language: json['language'] as String?,
      url: json['url'] as String?,
      description: json['description'] as String?,
      subjectIds: (json['subjectIds'] as List? ?? const []).cast<String>(),
      level: json['level'] as String?,
      source: ContentSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }
}

ResourceType _resourceTypeFromString(String? value) {
  return ResourceType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => ResourceType.book,
  );
}
