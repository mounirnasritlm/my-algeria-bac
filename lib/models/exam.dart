class Exam {
  final String id;

  final String subjectId;

  final String? year;

  final String? stream;

  final int durationMinutes;

  final List<ExamSection> sections;

  final String? scoringInfo;

  final String sourceId;

  const Exam({
    required this.id,
    required this.subjectId,
    this.year,
    this.stream,
    required this.durationMinutes,
    required this.sections,
    this.scoringInfo,
    required this.sourceId,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    final sections = <ExamSection>[
      for (final section in json['sections'] as List? ?? const [])
        ExamSection.fromJson(section as Map<String, dynamic>),
    ];

    return Exam(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      year: json['year'] as String?,
      stream: json['stream'] as String?,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      sections: sections,
      scoringInfo: json['scoringInfo'] as String?,
      sourceId: json['sourceId'] as String,
    );
  }
}

class ExamSection {
  final String id;

  final String title;

  final List<String> questionIds;

  final String? scoringInfo;

  const ExamSection({
    required this.id,
    required this.title,
    required this.questionIds,
    this.scoringInfo,
  });

  factory ExamSection.fromJson(Map<String, dynamic> json) {
    return ExamSection(
      id: json['id'] as String,
      title: json['title'] as String,
      questionIds: (json['questionIds'] as List? ?? const []).cast<String>(),
      scoringInfo: json['scoringInfo'] as String?,
    );
  }
}
