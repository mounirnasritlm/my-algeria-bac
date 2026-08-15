import 'exam_attempt.dart';

/// The activity of one day in a comeback plan.
enum ComebackDayKind {
  /// Open the concept lesson.
  review,

  /// Answer questions on the weak concept (quiz).
  practice,

  /// Take the full timed exam again.
  rematch,
}

/// One day of the 7-day comeback plan. Every day maps to a real screen.
class ComebackDay {
  final int day;

  final ComebackDayKind kind;

  final String title;

  final String description;

  const ComebackDay({
    required this.day,
    required this.kind,
    required this.title,
    required this.description,
  });
}

/// A 7-day recovery plan generated after a failed exam attempt.
class ComebackPlan {
  final String examId;

  /// Score of the most recent (failing) attempt.
  final double latestScore;

  /// Score of the attempt before that, if one exists.
  final double? previousScore;

  /// The weak concept this plan is built around.
  final String conceptId;

  final String lessonId;

  final List<ComebackDay> days;

  const ComebackPlan({
    required this.examId,
    required this.latestScore,
    required this.previousScore,
    required this.conceptId,
    required this.lessonId,
    required this.days,
  });

  /// Difference vs the previous attempt; null when there is no history.
  double? get improvement {
    final previous = previousScore;
    if (previous == null) {
      return null;
    }
    return latestScore - previous;
  }
}

/// A summary row of one completed exam attempt (from exam_attempts).
class ExamAttemptSummary {
  final String examId;

  final double scoreOn20;

  final int correctCount;

  final int totalQuestions;

  final int timeUsedSeconds;

  final DateTime completedAt;

  const ExamAttemptSummary({
    required this.examId,
    required this.scoreOn20,
    required this.correctCount,
    required this.totalQuestions,
    required this.timeUsedSeconds,
    required this.completedAt,
  });

  factory ExamAttemptSummary.fromMap(Map<String, Object?> map) {
    return ExamAttemptSummary(
      examId: map['exam_id'] as String,
      scoreOn20: (map['score_on_20'] as num).toDouble(),
      correctCount: (map['correct_count'] as num).toInt(),
      totalQuestions: (map['total_questions'] as num).toInt(),
      timeUsedSeconds: (map['time_used_seconds'] as num).toInt(),
      completedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['completed_at'] as num).toInt(),
      ),
    );
  }
}

/// A weak concept from an exam attempt plus its resolved lesson.
class ExamWeakConcept {
  final ExamConceptResult result;
  final String lessonId;

  const ExamWeakConcept({
    required this.result,
    required this.lessonId,
  });
}
