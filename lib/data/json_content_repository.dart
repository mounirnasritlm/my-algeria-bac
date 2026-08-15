import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/concept.dart';
import '../models/exam.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import '../models/resource.dart';
import '../models/subject.dart';
import '../models/teacher.dart';
import '../models/video.dart';
import 'content_repository.dart';

/// Loads content from the local JSON asset bundle.
///
/// All lists are loaded once on first access and cached for the lifetime of
/// the repository. This is the default repository used by the app until a
/// remote (e.g. GitHub) repository is introduced.
class JsonContentRepository implements ContentRepository {
  JsonContentRepository({AssetBundle? assetBundle})
      : _bundle = assetBundle ?? rootBundle;

  final AssetBundle _bundle;

  Future<_ContentBundle>? _cache;

  Future<_ContentBundle> get _content => _cache ??= _load();

  Future<_ContentBundle> _load() async {
    return _ContentBundle(
      version: await _loadVersion(),
      subjects: await _loadList('assets/content/subjects.json', Subject.fromJson),
      lessons: await _loadList('assets/content/lessons.json', Lesson.fromJson),
      concepts: await _loadList('assets/content/concepts.json', Concept.fromJson),
      questions: await _loadList('assets/content/questions.json', Question.fromJson),
      exams: await _loadList('assets/content/exams.json', Exam.fromJson),
      resources: await _loadList('assets/content/resources.json', Resource.fromJson),
      teachers: await _loadList('assets/content/teachers.json', Teacher.fromJson),
      videos: await _loadList('assets/content/videos.json', Video.fromJson),
    );
  }

  Future<String> _loadVersion() async {
    try {
      final raw = await _bundle.loadString('assets/content/content_version.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded['version'] as String? ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  Future<List<T>> _loadList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final raw = await _bundle.loadString(path);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in decoded) fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<String> getContentVersion() async => (await _content).version;

  @override
  Future<List<Subject>> getSubjects() async => (await _content).subjects;

  @override
  Future<Subject?> getSubject(String subjectId) async {
    for (final subject in (await _content).subjects) {
      if (subject.id == subjectId) {
        return subject;
      }
    }
    return null;
  }

  @override
  Future<List<Lesson>> getLessonsForSubject(String subjectId) async {
    return (await _content)
        .lessons
        .where((lesson) => lesson.subjectId == subjectId)
        .toList(growable: false);
  }

  @override
  Future<Lesson?> getLesson(String lessonId) async {
    for (final lesson in (await _content).lessons) {
      if (lesson.id == lessonId) {
        return lesson;
      }
    }
    return null;
  }

  @override
  Future<List<Concept>> getConceptsForLesson(String lessonId) async {
    return (await _content)
        .concepts
        .where((concept) => concept.lessonId == lessonId)
        .toList(growable: false);
  }

  @override
  Future<Concept?> getConcept(String conceptId) async {
    for (final concept in (await _content).concepts) {
      if (concept.id == conceptId) {
        return concept;
      }
    }
    return null;
  }

  @override
  Future<List<Question>> getQuestionsForLesson(String lessonId) async {
    return (await _content)
        .questions
        .where((question) => question.lessonId == lessonId)
        .toList(growable: false);
  }

  @override
  Future<List<Question>> getQuestionsForConcept(String conceptId) async {
    return (await _content)
        .questions
        .where((question) => question.conceptId == conceptId)
        .toList(growable: false);
  }

  @override
  Future<List<Exam>> getExams() async => (await _content).exams;

  @override
  Future<Exam?> getExam(String examId) async {
    for (final exam in (await _content).exams) {
      if (exam.id == examId) {
        return exam;
      }
    }
    return null;
  }

  @override
  Future<List<Question>> getQuestionsForExam(String examId) async {
    final exam = await getExam(examId);

    if (exam == null) {
      return [];
    }

    final ids = <String>{
      for (final section in exam.sections) ...section.questionIds,
    };

    final byId = {
      for (final question in (await _content).questions) question.id: question,
    };

    return [
      for (final id in exam.sections.expand((section) => section.questionIds))
        if (ids.contains(id) && byId[id] != null) byId[id]!,
    ];
  }

  @override
  Future<List<Resource>> getResourcesForSubject(String subjectId) async {
    return (await _content)
        .resources
        .where((resource) => resource.subjectIds.contains(subjectId))
        .toList(growable: false);
  }

  @override
  Future<List<Teacher>> getTeachers() async => (await _content).teachers;

  @override
  Future<List<Video>> getVideos() async => (await _content).videos;
}

class _ContentBundle {
  const _ContentBundle({
    required this.version,
    required this.subjects,
    required this.lessons,
    required this.concepts,
    required this.questions,
    required this.exams,
    required this.resources,
    required this.teachers,
    required this.videos,
  });

  final String version;
  final List<Subject> subjects;
  final List<Lesson> lessons;
  final List<Concept> concepts;
  final List<Question> questions;
  final List<Exam> exams;
  final List<Resource> resources;
  final List<Teacher> teachers;
  final List<Video> videos;
}
