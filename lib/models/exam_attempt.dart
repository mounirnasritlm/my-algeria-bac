import 'question.dart';

/// Result of one question inside a completed exam attempt.
class ExamQuestionResult {
  final Question question;

  final int? selectedIndex;

  final bool isCorrect;

  const ExamQuestionResult({
    required this.question,
    required this.selectedIndex,
    required this.isCorrect,
  });
}

/// Per-concept accuracy inside a single exam attempt (this attempt only,
/// not historical mastery).
class ExamConceptResult {
  final String conceptId;

  final String name;

  final int correct;

  final int attempts;

  final double accuracy;

  const ExamConceptResult({
    required this.conceptId,
    required this.name,
    required this.correct,
    required this.attempts,
    required this.accuracy,
  });

  bool get isStrength => attempts > 0 && accuracy >= 0.70;

  bool get isWeakness => attempts > 0 && accuracy < 0.50;
}

/// Immutable result of a submitted exam attempt.
class ExamAttempt {
  final String examId;

  final List<ExamQuestionResult> results;

  final int correctCount;

  final int totalQuestions;

  /// Correct/total scaled to /20, rounded to one decimal (demo estimate;
  /// official point allocations are not part of the source content).
  final double scoreOn20;

  final int timeUsedSeconds;

  final int durationMinutes;

  /// Strongest-first; only concepts actually attempted.
  final List<ExamConceptResult> conceptResults;

  const ExamAttempt({
    required this.examId,
    required this.results,
    required this.correctCount,
    required this.totalQuestions,
    required this.scoreOn20,
    required this.timeUsedSeconds,
    required this.durationMinutes,
    required this.conceptResults,
  });

  int get answeredCount => results.where((r) => r.selectedIndex != null).length;

  bool get hasResults => results.isNotEmpty;
}
