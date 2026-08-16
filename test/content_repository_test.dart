import 'package:flutter_test/flutter_test.dart';

import 'package:my_algeria_bac/data/json_content_repository.dart';
import 'package:my_algeria_bac/models/content_source.dart';
import 'package:my_algeria_bac/models/question.dart';

import 'helpers/demo_content_assets.dart';
import 'helpers/fake_asset_bundle.dart';

void main() {
  group('JsonContentRepository', () {
    late JsonContentRepository repository;

    setUp(() {
      repository = JsonContentRepository(
        assetBundle: FakeAssetBundle(demoContentAssets),
      );
    });

    test('reports the content version', () async {
      expect(await repository.getContentVersion(), '0.1.0');
    });

    test('loads all subjects', () async {
      final subjects = await repository.getSubjects();

      expect(subjects, hasLength(2));
      expect(subjects.first.id, 'mathematics');
      expect(subjects.first.nameForLanguage('en'), 'Mathematics');
      expect(subjects.first.nameForLanguage('fr'), 'Mathématiques');
    });

    test('getSubject returns the subject or null', () async {
      expect((await repository.getSubject('mathematics'))?.id, 'mathematics');
      expect(await repository.getSubject('does_not_exist'), isNull);
    });

    test('getChaptersForSubject filters by subject', () async {
      final chapters = await repository.getChaptersForSubject('mathematics');

      expect(chapters.map((chapter) => chapter.id),
          containsAll(['math_functions', 'math_derivatives']));
      expect(
        await repository.getChaptersForSubject('physics'),
        hasLength(1),
      );
    });

    test('getChapter returns the chapter or null', () async {
      final chapter = await repository.getChapter('math_functions');

      expect(chapter?.subjectId, 'mathematics');
      expect(await repository.getChapter('nope'), isNull);
    });

    test('getLessonsForChapter filters by chapter', () async {
      final lessons = await repository.getLessonsForChapter('math_functions');

      expect(lessons.map((lesson) => lesson.id),
          containsAll(['math_function_definition', 'math_function_domain']));
      expect(
        await repository.getLessonsForChapter('does_not_exist'),
        isEmpty,
      );
    });

    test('getLesson returns the lesson or null', () async {
      final lesson = await repository.getLesson('math_function_definition');

      expect(lesson?.subjectId, 'mathematics');
      expect(lesson?.chapterId, 'math_functions');
      expect(lesson?.estimatedMinutes, 15);
      expect(await repository.getLesson('nope'), isNull);
    });

    test('getConceptsForLesson filters by lesson', () async {
      final concepts =
          await repository.getConceptsForLesson('math_function_definition');

      expect(concepts.map((concept) => concept.id),
          containsAll(['function_definition']));
    });

    test('getConcept returns the concept or null', () async {
      final concept = await repository.getConcept('function_definition');

      expect(concept?.name, 'Function definition');
      expect(await repository.getConcept('missing_concept'), isNull);
    });

    test('getQuestionsForLesson filters by lesson', () async {
      final questions =
          await repository.getQuestionsForLesson('math_function_definition');

      expect(questions, hasLength(2));
      expect(questions.first.correctIndex, 0);
    });

    test('getQuestionsForConcept filters by concept', () async {
      final questions = await repository
          .getQuestionsForConcept('function_definition');

      expect(questions, hasLength(2));
      expect(questions.first.id, 'q_math_001');
    });

    test('loads exams', () async {
      final exams = await repository.getExams();

      expect(exams, hasLength(1));
      expect(exams.first.subjectId, 'mathematics');
      expect(exams.first.sections, hasLength(2));
    });

    test('getExam returns the exam or null', () async {
      expect((await repository.getExam('e_math_001'))?.id, 'e_math_001');
      expect(await repository.getExam('does_not_exist'), isNull);
    });

    test('getQuestionsForExam returns questions in section order', () async {
      final questions = await repository.getQuestionsForExam('e_math_001');

      expect(
        questions.map((question) => question.id),
        [
          'q_math_001',
          'q_math_002',
          'q_math_003',
          'q_math_004',
          'q_math_005',
        ],
      );
      expect(questions.first.conceptId, 'function_definition');

      expect(
        await repository.getQuestionsForExam('does_not_exist'),
        isEmpty,
      );
    });

    test('getSources returns the demo source', () async {
      final sources = await repository.getSources();

      expect(sources.map((source) => source.id), ['demo_source']);
      expect((await repository.getSource('demo_source'))?.type,
          ContentSourceType.demo);
      expect(await repository.getSource('missing_source'), isNull);
    });

    test('loads teachers, videos and worksheets', () async {
      expect(await repository.getTeachers(), isEmpty);
      expect(await repository.getVideosForLesson('math_function_definition'),
          isEmpty);
      expect(
          await repository.getWorksheetsForLesson('math_function_definition'),
          isEmpty);
    });

    test('getExamSolution returns null when no solution exists', () async {
      expect(await repository.getExamSolution('e_math_001'), isNull);
    });
  });

  group('Question.fromJson', () {
    test('parses a multiple-choice question', () {
      final json = {
        'id': 'q1',
        'subjectId': 'mathematics',
        'lessonId': 'lesson1',
        'conceptId': 'concept1',
        'type': 'multipleChoice',
        'prompt': 'Which symbol is commonly used for a function?',
        'options': ['f', 'z'],
        'correctIndex': 0,
        'explanation': 'f denotes a function.',
        'difficulty': 2,
        'sourceId': 'demo_source',
      };

      final question = Question.fromJson(json);

      expect(question.id, 'q1');
      expect(question.type, QuestionType.multipleChoice);
      expect(question.correctIndex, 0);
      expect(question.sourceId, 'demo_source');
    });

    test('parses an unknown question type with defaults', () {
      final json = {
        'id': 'q2',
        'subjectId': 'mathematics',
        'lessonId': 'lesson1',
        'conceptId': 'concept1',
        'prompt': 'Type?',
        'sourceId': 'demo_source',
      };

      final question = Question.fromJson(json);

      expect(question.type, QuestionType.multipleChoice);
      expect(question.options, isEmpty);
      expect(question.correctIndex, isNull);
      expect(question.validationStatus, 'CONTENT_REQUIRES_VERIFICATION');
    });
  });
}
