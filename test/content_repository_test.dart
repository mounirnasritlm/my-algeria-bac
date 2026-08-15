import 'package:flutter_test/flutter_test.dart';

import 'package:my_algeria_bac/data/json_content_repository.dart';
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
      expect(subjects.first.id, 'math');
      expect(subjects.first.name, 'Mathematics');
    });

    test('getSubject returns the subject or null', () async {
      expect((await repository.getSubject('math'))?.id, 'math');
      expect(await repository.getSubject('does_not_exist'), isNull);
    });

    test('getLessonsForSubject filters by subject', () async {
      final lessons = await repository.getLessonsForSubject('math');

      expect(lessons.map((lesson) => lesson.id),
          containsAll(['math_functions', 'math_derivatives']));
      expect(
        await repository.getLessonsForSubject('physics'),
        hasLength(1),
      );
    });

    test('getLesson returns the lesson or null', () async {
      final lesson = await repository.getLesson('math_functions');

      expect(lesson?.subjectId, 'math');
      expect(lesson?.estimatedMinutes, 15);
      expect(await repository.getLesson('nope'), isNull);
    });

    test('getConceptsForLesson filters by lesson', () async {
      final concepts = await repository.getConceptsForLesson('math_functions');

      expect(concepts.map((concept) => concept.id),
          containsAll(['function_definition', 'domain']));
    });

    test('getConcept returns the concept or null', () async {
      final concept = await repository.getConcept('function_definition');

      expect(concept?.name, 'Function definition');
      expect(await repository.getConcept('missing_concept'), isNull);
    });

    test('getQuestionsForLesson filters by lesson', () async {
      final questions =
          await repository.getQuestionsForLesson('math_functions');

      expect(questions, hasLength(4));
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
      expect(exams.first.subjectId, 'math');
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

    test('getResourcesForSubject filters by subject ids', () async {
      final resources = await repository.getResourcesForSubject('math');

      expect(resources.map((resource) => resource.id), ['r_math_001']);
      expect(await repository.getResourcesForSubject('physics'), isEmpty);
    });

    test('loads teachers and videos', () async {
      expect(await repository.getTeachers(), isEmpty);
      expect(await repository.getVideos(), isEmpty);
    });
  });

  group('Question.fromJson', () {
    test('parses a multiple-choice question', () {
      final json = {
        'id': 'q1',
        'subjectId': 'math',
        'lessonId': 'lesson1',
        'conceptId': 'concept1',
        'type': 'multipleChoice',
        'prompt': 'Which symbol is commonly used for a function?',
        'options': ['f', 'z'],
        'correctIndex': 0,
        'explanation': 'f denotes a function.',
        'difficulty': 2,
        'source': {'sourceType': 'demo_content', 'verified': false},
      };

      final question = Question.fromJson(json);

      expect(question.id, 'q1');
      expect(question.type, QuestionType.multipleChoice);
      expect(question.correctIndex, 0);
      expect(question.source.sourceType, 'demo_content');
      expect(question.source.verified, isFalse);
    });

    test('parses an unknown question type with defaults', () {
      final json = {
        'id': 'q2',
        'subjectId': 'math',
        'lessonId': 'lesson1',
        'conceptId': 'concept1',
        'prompt': 'Type?',
        'source': {'sourceType': 'demo_content'},
      };

      final question = Question.fromJson(json);

      expect(question.type, QuestionType.multipleChoice);
      expect(question.options, isEmpty);
      expect(question.correctIndex, isNull);
      expect(question.validationStatus, 'CONTENT_REQUIRES_VERIFICATION');
    });
  });
}
