import '../l10n/engine_strings.dart';
import '../models/comeback.dart';
import '../models/exam_attempt.dart';

/// Pure comeback logic. No I/O, no AI: the plan is derived from real exam
/// results and the student's own weak concepts.

/// The BAC passing grade (10/20). A documented product heuristic mirroring
/// the official passing bar — not a claim about any individual outcome.
bool isPassingScore(double scoreOn20) => scoreOn20 >= 10.0;

/// The weakest concept (lowest accuracy) among the weak ones of an attempt.
/// Returns null when nothing was weak.
ExamConceptResult? primaryWeakConcept(ExamAttempt attempt) {
  final weak = attempt.conceptResults.where((c) => c.isWeakness).toList();

  if (weak.isEmpty) {
    return null;
  }

  weak.sort((a, b) => a.accuracy.compareTo(b.accuracy));

  return weak.first;
}

/// Builds a 7-day recovery plan around one weak concept.
///
/// [weakConceptLessonId] resolves the weak concept's lesson; the caller
/// (UI layer) provides it via the content repository.
ComebackPlan buildComebackPlan({
  required String examId,
  required double latestScore,
  required double? previousScore,
  required ExamConceptResult weakConcept,
  required String weakConceptLessonId,
  String languageCode = 'en',
}) {
  return ComebackPlan(
    examId: examId,
    latestScore: latestScore,
    previousScore: previousScore,
    conceptId: weakConcept.conceptId,
    lessonId: weakConceptLessonId,
    days: [
      for (var day = 1; day <= 7; day++)
        ComebackDay(
          day: day,
          kind: _comebackKindFor(day),
          title: comebackDayTitle(day, languageCode),
          description: comebackDayDescription(day, languageCode),
        ),
    ],
  );
}

ComebackDayKind _comebackKindFor(int day) {
  switch (day) {
    case 1:
      return ComebackDayKind.review;
    case 2:
    case 3:
      return ComebackDayKind.practice;
    case 4:
    case 7:
      return ComebackDayKind.rematch;
    case 5:
      return ComebackDayKind.practice;
    default:
      return ComebackDayKind.review;
  }
}
