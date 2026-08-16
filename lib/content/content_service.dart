import 'dart:convert';

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
import 'content_bundle.dart';
import 'content_loader.dart';
import 'validation/content_validator.dart';

/// Loads a whole content bundle from a [ContentLoader], parses it into
/// models, and validates it.
///
/// A structural failure (unreadable file, malformed JSON, unparseable item)
/// throws the underlying error. Validation findings never throw: they are
/// reported on [LoadedContent.validation] so callers decide what to do with a
/// bundle that parses but fails cross-reference checks.
class ContentService {
  ContentService({required this.loader, ContentValidator? validator})
      : _validator = validator ?? const ContentValidator();

  final ContentLoader loader;

  final ContentValidator _validator;

  /// Loads, parses and validates the whole bundle from the underlying loader.
  Future<LoadedContent> loadContent() async {
    final manifest = await _loadManifest();
    final bundle = ContentBundle(
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
    return LoadedContent(
      bundle: bundle,
      validation: await _validator.validate(bundle),
    );
  }

  static const String _manifestPath = 'manifest.json';

  Future<ContentManifest> _loadManifest() async {
    final raw = await loader.loadFile(_manifestPath);
    return ContentManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Loads every file of one collection (e.g. every `subjects/...` file) into
  /// a single list, in manifest order. A file that is absent from the source
  /// is skipped so optional collections may be missing.
  Future<List<T>> _loadCollection<T>(
    ContentManifest manifest,
    String collection,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final result = <T>[];
    for (final file in manifest.filesForCollection(collection)) {
      final String raw;
      try {
        raw = await loader.loadFile(file.path);
      } on ContentNotFoundException {
        continue;
      }
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          result.add(fromJson(item as Map<String, dynamic>));
        }
      }
    }
    return result;
  }
}
