import 'dart:convert';

import 'package:flutter/services.dart';

import '../content/asset_content_loader.dart';
import '../content/content_loader.dart';
import '../models/chapter.dart';
import '../models/concept.dart';
import '../models/content_manifest.dart';
import '../models/content_source.dart';
import '../models/exam.dart';
import '../models/exam_solution.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import '../models/subject.dart';
import '../models/teacher.dart';
import '../models/video_resource.dart';
import '../models/worksheet.dart';
import 'content_repository.dart';

/// Loads content from a [ContentLoader] (bundled assets by default),
/// following the manifest.
///
/// All lists are loaded once on first access and cached for the lifetime of
/// the repository. This is the default repository used by the app; a
/// cache-backed or remote loader can be supplied instead.
class JsonContentRepository implements ContentRepository {
  JsonContentRepository({AssetBundle? assetBundle, ContentLoader? loader})
      : _loader = loader ?? AssetContentLoader(assetBundle: assetBundle);

  final ContentLoader _loader;

  Future<_ContentBundle>? _cache;

  Future<_ContentBundle> get _content => _cache ??= _load();

  Future<_ContentBundle> _load() async {
    final manifest = await _loadManifest();

    return _ContentBundle(
      manifest: manifest,
      subjects: await _loadCollection(manifest, 'subjects', Subject.fromJson),
      chapters: await _loadCollection(manifest, 'chapters', Chapter.fromJson),
      lessons: await _loadCollection(manifest, 'lessons', Lesson.fromJson),
      concepts: await _loadCollection(manifest, 'concepts', Concept.fromJson),
      questions: await _loadCollection(manifest, 'questions', Question.fromJson),
      exams: await _loadCollection(manifest, 'exams', Exam.fromJson),
      solutions:
          await _loadCollection(manifest, 'solutions', ExamSolution.fromJson),
      sources:
          await _loadCollection(manifest, 'sources', ContentSource.fromJson),
      teachers: await _loadCollection(manifest, 'teachers', Teacher.fromJson),
      videos:
          await _loadCollection(manifest, 'videos', VideoResource.fromJson),
      worksheets:
          await _loadCollection(manifest, 'worksheets', Worksheet.fromJson),
    );
  }

  Future<ContentManifest> _loadManifest() async {
    final raw = await _loader.loadFile('manifest.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return ContentManifest.fromJson(decoded);
  }

  /// Loads every file of one collection (e.g. every `subjects/...` file) into
  /// a single list, in manifest order. A file that is absent from the source
  /// is treated as an empty list so partial bundles load cleanly.
  Future<List<T>> _loadCollection<T>(
    ContentManifest manifest,
    String collection,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final result = <T>[];

    for (final file in manifest.filesForCollection(collection)) {
      result.addAll(await _loadList(file.path, fromJson, tolerant: true));
    }

    return result;
  }

  Future<List<T>> _loadList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    bool tolerant = false,
  }) async {
    String raw;
    try {
      raw = await _loader.loadFile(path);
    } catch (_) {
      if (tolerant) {
        return [];
      }
      rethrow;
    }

    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      return [];
    }

    return [
      for (final item in decoded) fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<String> getContentVersion() async =>
      (await _content).manifest.contentVersion;

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
  Future<List<Chapter>> getChaptersForSubject(String subjectId) async {
    return (await _content)
        .chapters
        .where((chapter) => chapter.subjectId == subjectId)
        .toList(growable: false);
  }

  @override
  Future<Chapter?> getChapter(String chapterId) async {
    for (final chapter in (await _content).chapters) {
      if (chapter.id == chapterId) {
        return chapter;
      }
    }
    return null;
  }

  @override
  Future<List<Lesson>> getLessonsForChapter(String chapterId) async {
    return (await _content)
        .lessons
        .where((lesson) => lesson.chapterId == chapterId)
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
  Future<ExamSolution?> getExamSolution(String examId) async {
    for (final solution in (await _content).solutions) {
      if (solution.examId == examId) {
        return solution;
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
  Future<List<ContentSource>> getSources() async => (await _content).sources;

  @override
  Future<ContentSource?> getSource(String sourceId) async {
    for (final source in (await _content).sources) {
      if (source.id == sourceId) {
        return source;
      }
    }
    return null;
  }

  @override
  Future<List<Teacher>> getTeachers() async => (await _content).teachers;

  @override
  Future<Teacher?> getTeacher(String teacherId) async {
    for (final teacher in (await _content).teachers) {
      if (teacher.id == teacherId) {
        return teacher;
      }
    }
    return null;
  }

  @override
  Future<List<VideoResource>> getVideosForLesson(String lessonId) async {
    return (await _content)
        .videos
        .where((video) => video.lessonId == lessonId)
        .toList(growable: false);
  }

  @override
  Future<List<Worksheet>> getWorksheetsForLesson(String lessonId) async {
    return (await _content)
        .worksheets
        .where((worksheet) => worksheet.lessonId == lessonId)
        .toList(growable: false);
  }
}

class _ContentBundle {
  const _ContentBundle({
    required this.manifest,
    required this.subjects,
    required this.chapters,
    required this.lessons,
    required this.concepts,
    required this.questions,
    required this.exams,
    required this.solutions,
    required this.sources,
    required this.teachers,
    required this.videos,
    required this.worksheets,
  });

  final ContentManifest manifest;
  final List<Subject> subjects;
  final List<Chapter> chapters;
  final List<Lesson> lessons;
  final List<Concept> concepts;
  final List<Question> questions;
  final List<Exam> exams;
  final List<ExamSolution> solutions;
  final List<ContentSource> sources;
  final List<Teacher> teachers;
  final List<VideoResource> videos;
  final List<Worksheet> worksheets;
}
