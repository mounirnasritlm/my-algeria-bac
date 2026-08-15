class Subject {
  final String id;
  final String name;
  final String language;
  final String icon;
  final List<String> lessonIds;

  const Subject({
    required this.id,
    required this.name,
    required this.language,
    required this.icon,
    required this.lessonIds,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      name: json['name'] as String,
      language: json['language'] as String? ?? 'fr',
      icon: json['icon'] as String? ?? '',
      lessonIds: (json['lessonIds'] as List? ?? const []).cast<String>(),
    );
  }
}
