class ExamSolution {
  final String id;

  final String examId;

  final String sourceId;

  final String? documentUrl;

  final Map<String, String> questionExplanations;

  final bool verified;

  const ExamSolution({
    required this.id,
    required this.examId,
    required this.sourceId,
    required this.documentUrl,
    required this.questionExplanations,
    required this.verified,
  });

  factory ExamSolution.fromJson(Map<String, dynamic> json) {
    final explanationsRaw = Map<String, dynamic>.from(
      json['questionExplanations'] ?? const <String, dynamic>{},
    );

    return ExamSolution(
      id: json['id'] as String,
      examId: json['examId'] as String,
      sourceId: json['sourceId'] as String,
      documentUrl: json['documentUrl'] as String?,
      questionExplanations: explanationsRaw.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      verified: json['verified'] as bool? ?? false,
    );
  }
}
