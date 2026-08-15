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
}) {
  return ComebackPlan(
    examId: examId,
    latestScore: latestScore,
    previousScore: previousScore,
    conceptId: weakConcept.conceptId,
    lessonId: weakConceptLessonId,
    days: const [
      ComebackDay(
        day: 1,
        kind: ComebackDayKind.review,
        title: 'Concept review',
        description: 'Re-read the lesson for your weak concept.',
      ),
      ComebackDay(
        day: 2,
        kind: ComebackDayKind.practice,
        title: '10 targeted exercises',
        description: 'Practice questions aimed at your weak concept.',
      ),
      ComebackDay(
        day: 3,
        kind: ComebackDayKind.practice,
        title: 'Targeted quiz',
        description: 'Re-test your weak concept in a short quiz.',
      ),
      ComebackDay(
        day: 4,
        kind: ComebackDayKind.rematch,
        title: 'Timed exercise',
        description: 'A timed exam section under real conditions.',
      ),
      ComebackDay(
        day: 5,
        kind: ComebackDayKind.practice,
        title: 'Review your mistakes',
        description: 'Consolidate before the rematch.',
      ),
      ComebackDay(
        day: 6,
        kind: ComebackDayKind.review,
        title: 'Final review',
        description: 'Quick refresh of the concept and its rules.',
      ),
      ComebackDay(
        day: 7,
        kind: ComebackDayKind.rematch,
        title: 'Boss rematch',
        description: 'Take the full exam again and beat your score.',
      ),
    ],
  );
}
