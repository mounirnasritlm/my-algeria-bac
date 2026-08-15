import '../models/exam_attempt.dart';
import '../models/exam_session.dart';

/// Pure exam scoring. No I/O, no AI, no invented content: every question
/// counts equally toward /20 and unanswered questions score zero.

/// Correct/total scaled to /20, rounded to one decimal.
double scoreOn20({required int correct, required int total}) {
  if (total == 0) {
    return 0;
  }
  final raw = correct / total * 20;
  return (raw * 10).roundToDouble() / 10;
}

/// Heuristic label for time usage inside an attempt.
/// Not a claim about BAC norms — a product heuristic, as documented.
String timeManagementLabel({
  required int timeUsedSeconds,
  required int durationMinutes,
}) {
  final durationSeconds = durationMinutes * 60;
  if (durationSeconds <= 0) {
    return 'Unknown';
  }

  final ratio = timeUsedSeconds / durationSeconds;

  if (ratio <= 0.70) {
    return 'Good';
  }
  if (ratio <= 0.90) {
    return 'Fair';
  }
  return 'Tight';
}

/// Builds an immutable [ExamAttempt] from an in-progress [ExamSession].
/// Concept names are left as ids here and resolved by the report screen,
/// keeping this function pure and unit-testable.
ExamAttempt buildExamAttempt({
  required ExamSession session,
  required int timeUsedSeconds,
}) {
  final results = <ExamQuestionResult>[
    for (final question in session.questions)
      ExamQuestionResult(
        question: question,
        selectedIndex: session.answers[question.id],
        isCorrect: session.answers[question.id] == question.correctIndex,
      ),
  ];

  final correctCount =
      results.where((result) => result.isCorrect).length;

  return ExamAttempt(
    examId: session.exam.id,
    results: results,
    correctCount: correctCount,
    totalQuestions: session.totalQuestions,
    scoreOn20: scoreOn20(correct: correctCount, total: session.totalQuestions),
    timeUsedSeconds: timeUsedSeconds,
    durationMinutes: session.exam.durationMinutes,
    conceptResults: _conceptResults(results),
  );
}

List<ExamConceptResult> _conceptResults(
  List<ExamQuestionResult> results,
) {
  final byConcept = <String, List<ExamQuestionResult>>{};

  for (final result in results) {
    byConcept
        .putIfAbsent(result.question.conceptId, () => [])
        .add(result);
  }

  final conceptResults = <ExamConceptResult>[];

  for (final entry in byConcept.entries) {
    final attempts = entry.value.length;
    final correct =
        entry.value.where((result) => result.isCorrect).length;

    conceptResults.add(
      ExamConceptResult(
        conceptId: entry.key,
        name: entry.key,
        correct: correct,
        attempts: attempts,
        accuracy: correct / attempts,
      ),
    );
  }

  conceptResults.sort((a, b) {
    final byAccuracy = b.accuracy.compareTo(a.accuracy);
    return byAccuracy != 0 ? byAccuracy : a.conceptId.compareTo(b.conceptId);
  });

  return conceptResults;
}
