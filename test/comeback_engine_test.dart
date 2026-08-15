import 'package:flutter_test/flutter_test.dart';
import 'package:my_algeria_bac/data/comeback_engine.dart';
import 'package:my_algeria_bac/models/comeback.dart';
import 'package:my_algeria_bac/models/exam_attempt.dart';

ExamAttempt _attempt({
  required double score,
  List<ExamConceptResult> concepts = const [],
}) {
  return ExamAttempt(
    examId: 'demo_math_exam_001',
    results: const [],
    correctCount: 0,
    totalQuestions: 1,
    scoreOn20: score,
    timeUsedSeconds: 0,
    durationMinutes: 180,
    conceptResults: concepts,
  );
}

void main() {
  group('isPassingScore', () {
    test('10/20 or more is a pass', () {
      expect(isPassingScore(9.9), isFalse);
      expect(isPassingScore(10.0), isTrue);
      expect(isPassingScore(16.5), isTrue);
    });
  });

  group('primaryWeakConcept', () {
    test('returns the weakest weak concept', () {
      final attempt = _attempt(
        score: 5.0,
        concepts: const [
          ExamConceptResult(
            conceptId: 'strong',
            name: 'Strong',
            correct: 3,
            attempts: 4,
            accuracy: 0.75,
          ),
          ExamConceptResult(
            conceptId: 'weak_a',
            name: 'Weak A',
            correct: 1,
            attempts: 4,
            accuracy: 0.25,
          ),
          ExamConceptResult(
            conceptId: 'weak_b',
            name: 'Weak B',
            correct: 2,
            attempts: 4,
            accuracy: 0.50,
          ),
        ],
      );

      expect(primaryWeakConcept(attempt)?.conceptId, 'weak_a');
    });

    test('returns null when nothing is weak', () {
      final attempt = _attempt(
        score: 15.0,
        concepts: const [
          ExamConceptResult(
            conceptId: 'c1',
            name: 'C1',
            correct: 4,
            attempts: 4,
            accuracy: 1.0,
          ),
        ],
      );

      expect(primaryWeakConcept(attempt), isNull);
    });

    test('returns null on an empty attempt', () {
      expect(primaryWeakConcept(_attempt(score: 5.0)), isNull);
    });
  });

  group('buildComebackPlan', () {
    const weakConcept = ExamConceptResult(
      conceptId: 'complex',
      name: 'Complex',
      correct: 1,
      attempts: 4,
      accuracy: 0.25,
    );

    final plan = buildComebackPlan(
      examId: 'demo_math_exam_001',
      latestScore: 6.5,
      previousScore: 4.0,
      weakConcept: weakConcept,
      weakConceptLessonId: 'lesson_001',
    );

    test('is a 7-day plan around the weak concept', () {
      expect(plan.days, hasLength(7));
      expect(plan.conceptId, 'complex');
      expect(plan.lessonId, 'lesson_001');
      expect(plan.examId, 'demo_math_exam_001');
    });

    test('days are ordered and end with a rematch', () {
      expect(plan.days.first.day, 1);
      expect(plan.days.last.day, 7);
      expect(plan.days.last.kind, ComebackDayKind.rematch);
      expect(plan.days.last.title, 'Boss rematch');
    });

    test('improvement is latest minus previous', () {
      expect(plan.improvement, 2.5);
    });

    test('improvement is null without previous score', () {
      final fresh = buildComebackPlan(
        examId: 'demo_math_exam_001',
        latestScore: 6.5,
        previousScore: null,
        weakConcept: weakConcept,
        weakConceptLessonId: 'lesson_001',
      );

      expect(fresh.improvement, isNull);
    });

    test('every day maps to a launchable screen kind', () {
      for (final day in plan.days) {
        expect(
          day.kind,
          anyOf(
            ComebackDayKind.review,
            ComebackDayKind.practice,
            ComebackDayKind.rematch,
          ),
        );
      }
    });
  });

  group('ExamAttemptSummary.fromMap', () {
    test('parses a stored attempt row', () {
      final summary = ExamAttemptSummary.fromMap({
        'exam_id': 'demo_math_exam_001',
        'score_on_20': 11.5,
        'correct_count': 6,
        'total_questions': 10,
        'time_used_seconds': 5400,
        'completed_at': 1700000000000,
      });

      expect(summary.examId, 'demo_math_exam_001');
      expect(summary.scoreOn20, 11.5);
      expect(summary.correctCount, 6);
      expect(summary.totalQuestions, 10);
      expect(summary.timeUsedSeconds, 5400);
      expect(summary.completedAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
    });
  });
}
