import 'package:flutter_test/flutter_test.dart';

import 'package:my_algeria_bac/data/exam_scoring.dart';
import 'package:my_algeria_bac/models/exam.dart';
import 'package:my_algeria_bac/models/exam_session.dart';
import 'package:my_algeria_bac/models/question.dart';
import 'package:my_algeria_bac/models/source.dart';

void main() {
  group('scoreOn20', () {
    test('scales correct/total to /20', () {
      expect(scoreOn20(correct: 3, total: 4), 15.0);
      expect(scoreOn20(correct: 1, total: 2), 10.0);
    });

    test('rounds to one decimal', () {
      expect(scoreOn20(correct: 1, total: 3), closeTo(6.7, 0.05));
      expect(scoreOn20(correct: 2, total: 3), closeTo(13.3, 0.05));
    });

    test('returns zero for empty exams', () {
      expect(scoreOn20(correct: 0, total: 0), 0);
    });
  });

  group('timeManagementLabel', () {
    test('buckets by fraction of time used', () {
      expect(
        timeManagementLabel(timeUsedSeconds: 50 * 60, durationMinutes: 100),
        'Good',
      );
      expect(
        timeManagementLabel(timeUsedSeconds: 80 * 60, durationMinutes: 100),
        'Fair',
      );
      expect(
        timeManagementLabel(timeUsedSeconds: 95 * 60, durationMinutes: 100),
        'Tight',
      );
    });

    test('handles zero duration', () {
      expect(
        timeManagementLabel(timeUsedSeconds: 0, durationMinutes: 0),
        'Unknown',
      );
    });
  });

  group('buildExamAttempt', () {
    final exam = Exam(
      id: 'exam_001',
      subjectId: 'math',
      year: 'UNKNOWN',
      stream: null,
      durationMinutes: 100,
      sections: const [
        ExamSection(
          id: 's1',
          title: 'Exercise 1',
          questionIds: ['q1', 'q2'],
        ),
      ],
      scoringInfo: 'UNKNOWN',
      source: ContentSource.demoContent,
    );

    Question question(String id, String conceptId, int correctIndex) {
      return Question(
        id: id,
        subjectId: 'math',
        lessonId: 'lesson',
        conceptId: conceptId,
        prompt: 'Prompt $id',
        options: const ['a', 'b', 'c'],
        correctIndex: correctIndex,
        source: ContentSource.demoContent,
      );
    }

    ExamSession session({
      required Map<String, int> answers,
    }) {
      return ExamSession(
        exam: exam,
        questions: [
          question('q1', 'function_definition', 0),
          question('q2', 'function_definition', 1),
        ],
        startedAt: DateTime(2026),
        answers: answers,
      );
    }

    test('computes score, correct count, and concept results', () {
      final attempt = buildExamAttempt(
        session: session(answers: {'q1': 0, 'q2': 1}),
        timeUsedSeconds: 40 * 60,
      );

      expect(attempt.correctCount, 2);
      expect(attempt.totalQuestions, 2);
      expect(attempt.answeredCount, 2);
      expect(attempt.scoreOn20, 20.0);
      expect(attempt.examId, 'exam_001');
      expect(attempt.durationMinutes, 100);

      expect(attempt.conceptResults, hasLength(1));
      expect(attempt.conceptResults.single.conceptId, 'function_definition');
      expect(attempt.conceptResults.single.accuracy, 1.0);
      expect(attempt.conceptResults.single.isStrength, isTrue);
      expect(attempt.conceptResults.single.isWeakness, isFalse);
    });

    test('counts unanswered as wrong', () {
      final attempt = buildExamAttempt(
        session: session(answers: {'q1': 0}),
        timeUsedSeconds: 40 * 60,
      );

      expect(attempt.answeredCount, 1);
      expect(attempt.correctCount, 1);
      expect(attempt.scoreOn20, 10.0);
    });

    test('flags weakness when accuracy is low', () {
      final attempt = buildExamAttempt(
        session: session(answers: {'q1': 2, 'q2': 0}),
        timeUsedSeconds: 40 * 60,
      );

      expect(attempt.correctCount, 0);
      expect(attempt.conceptResults.single.isWeakness, isTrue);
      expect(attempt.conceptResults.single.isStrength, isFalse);
    });

    test('sorts concept results strongest-first', () {
      final mixedExam = Exam(
        id: 'exam_002',
        subjectId: 'math',
        year: 'UNKNOWN',
        stream: null,
        durationMinutes: 100,
        sections: const [
          ExamSection(id: 's1', title: 'Exercise 1', questionIds: ['q1']),
          ExamSection(id: 's2', title: 'Exercise 2', questionIds: ['q3']),
        ],
        scoringInfo: 'UNKNOWN',
        source: ContentSource.demoContent,
      );

      final mixedSession = ExamSession(
        exam: mixedExam,
        questions: [
          question('q1', 'function_definition', 0),
          question('q3', 'derivative_definition', 0),
        ],
        startedAt: DateTime(2026),
        answers: {'q1': 0, 'q3': 2},
      );

      final attempt = buildExamAttempt(
        session: mixedSession,
        timeUsedSeconds: 40 * 60,
      );

      expect(attempt.conceptResults, hasLength(2));
      expect(
        attempt.conceptResults.first.conceptId,
        'function_definition', // 100% first
      );
      expect(
        attempt.conceptResults.last.conceptId,
        'derivative_definition', // 0% last
      );
    });
  });
}
