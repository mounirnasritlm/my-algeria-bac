class Lesson {
  final String id;

  final String subjectId;

  final String chapterId;

  final Map<String, String> titles;

  final Map<String, String> descriptions;

  final List<String> conceptIds;

  final int estimatedMinutes;

  final String sourceId;

  const Lesson({
    required this.id,
    required this.subjectId,
    required this.chapterId,
    required this.titles,
    required this.descriptions,
    required this.conceptIds,
    required this.estimatedMinutes,
    required this.sourceId,
  });

  String titleForLanguage(String language) {
    return titles[language] ??
        titles['ar'] ??
        titles['fr'] ??
        titles['en'] ??
        id;
  }

  String descriptionForLanguage(String language) {
    return descriptions[language] ??
        descriptions['ar'] ??
        descriptions['fr'] ??
        descriptions['en'] ??
        '';
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final titlesRaw = Map<String, dynamic>.from(json['title'] as Map);

    final descriptionsRaw = Map<String, dynamic>.from(
      json['description'] as Map,
    );

    return Lesson(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      chapterId: json['chapterId'] as String,
      titles: titlesRaw.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      descriptions: descriptionsRaw.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      conceptIds: List<String>.from(json['conceptIds'] ?? const []),
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 0,
      sourceId: json['sourceId'] as String,
    );
  }
}
