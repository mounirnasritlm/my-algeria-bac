enum ContentSourceType {
  official,
  teacher,
  publisher,
  website,
  youtube,
  telegram,
  facebook,
  community,
  editorial,
  demo,
}

ContentSourceType sourceTypeFromString(String value) {
  switch (value) {
    case 'official':
      return ContentSourceType.official;
    case 'teacher':
      return ContentSourceType.teacher;
    case 'publisher':
      return ContentSourceType.publisher;
    case 'website':
      return ContentSourceType.website;
    case 'youtube':
      return ContentSourceType.youtube;
    case 'telegram':
      return ContentSourceType.telegram;
    case 'facebook':
      return ContentSourceType.facebook;
    case 'community':
      return ContentSourceType.community;
    case 'editorial':
      return ContentSourceType.editorial;
    case 'demo':
    default:
      return ContentSourceType.demo;
  }
}

/// A first-class record of where content came from. Every educational item
/// points back to one of these by id, so official exams, teacher uploads,
/// publisher material, and community resources are never conflated.
class ContentSource {
  final String id;

  final ContentSourceType type;

  final String name;

  final String? author;

  final String? url;

  final String? publication;

  final String? year;

  final bool verified;

  const ContentSource({
    required this.id,
    required this.type,
    required this.name,
    required this.author,
    required this.url,
    required this.publication,
    required this.year,
    required this.verified,
  });

  factory ContentSource.fromJson(Map<String, dynamic> json) {
    return ContentSource(
      id: json['id'] as String,
      type: sourceTypeFromString(json['type'] as String),
      name: json['name'] as String,
      author: json['author'] as String?,
      url: json['url'] as String?,
      publication: json['publication'] as String?,
      year: json['year'] as String?,
      verified: json['verified'] as bool? ?? false,
    );
  }
}
