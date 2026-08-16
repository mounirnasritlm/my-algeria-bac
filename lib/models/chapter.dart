class Chapter {
  final String id;

  final String subjectId;

  final Map<String, String> names;

  final List<String> lessonIds;

  final int order;

  const Chapter({
    required this.id,
    required this.subjectId,
    required this.names,
    required this.lessonIds,
    required this.order,
  });

  String nameForLanguage(String language) {
    return names[language] ??
        names['ar'] ??
        names['fr'] ??
        names['en'] ??
        id;
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    final namesRaw = Map<String, dynamic>.from(json['names'] as Map);

    return Chapter(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      names: namesRaw.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      lessonIds: List<String>.from(json['lessonIds'] ?? const []),
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}
