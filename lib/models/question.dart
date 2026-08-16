enum QuestionType { multipleChoice, trueFalse, numeric }

class Question {
  final String id;

  final String subjectId;

  final String lessonId;

  final String conceptId;

  final QuestionType type;

  final String prompt;

  final List<String> options;

  final int? correctIndex;

  final double? numericAnswer;

  final String explanation;

  final int difficulty;

  final String sourceId;

  final String validationStatus;

  const Question({
    required this.id,
    required this.subjectId,
    required this.lessonId,
    required this.conceptId,
    this.type = QuestionType.multipleChoice,
    required this.prompt,
    this.options = const [],
    this.correctIndex,
    this.numericAnswer,
    this.explanation = '',
    this.difficulty = 1,
    required this.sourceId,
    this.validationStatus = 'CONTENT_REQUIRES_VERIFICATION',
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      lessonId: json['lessonId'] as String,
      conceptId: json['conceptId'] as String,
      type: _questionTypeFromString(json['type'] as String?),
      prompt: json['prompt'] as String,
      options: (json['options'] as List? ?? const []).cast<String>(),
      correctIndex: (json['correctIndex'] as num?)?.toInt(),
      numericAnswer: (json['numericAnswer'] as num?)?.toDouble(),
      explanation: json['explanation'] as String? ?? '',
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      sourceId: json['sourceId'] as String,
      validationStatus:
          json['validationStatus'] as String? ?? 'CONTENT_REQUIRES_VERIFICATION',
    );
  }
}

QuestionType _questionTypeFromString(String? value) {
  return QuestionType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => QuestionType.multipleChoice,
  );
}
