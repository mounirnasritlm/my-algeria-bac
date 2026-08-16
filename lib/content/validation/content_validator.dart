import '../../config/content_schema_config.dart';
import '../../models/chapter.dart';
import '../../models/concept.dart';
import '../../models/content_manifest.dart';
import '../../models/content_source.dart';
import '../../models/exam.dart';
import '../../models/exam_solution.dart';
import '../../models/lesson.dart';
import '../../models/question.dart';
import '../../models/subject.dart';
import '../../models/teacher.dart';
import '../../models/video_resource.dart';
import '../../models/worksheet.dart';
import '../content_bundle.dart';
import 'content_validation_result.dart';

/// Validates a parsed [ContentBundle] before it is trusted.
///
/// The validator rejects broken content, it never repairs it: a bundle that
/// fails validation is refused and the previous valid bundle stays in use.
/// Missing or malformed cross-references, duplicate ids, and structurally
/// unusable items are errors. Attribution gaps (unverified sources, empty
/// optional collections) are warnings only.
class ContentValidator {
  const ContentValidator();

  Future<ContentValidationResult> validate(ContentBundle bundle) async {
    final issues = <ContentValidationIssue>[];

    _validateManifest(bundle.manifest, issues);
    _validateSources(bundle, issues);
    _validateSubjects(bundle, issues);
    _validateChapters(bundle, issues);
    _validateLessons(bundle, issues);
    _validateConcepts(bundle, issues);
    _validateQuestions(bundle, issues);
    _validateExams(bundle, issues);
    _validateSolutions(bundle, issues);
    _validateTeachers(bundle, issues);
    _validateVideos(bundle, issues);
    _validateWorksheets(bundle, issues);

    return ContentValidationResult(issues);
  }

  void _validateManifest(ContentManifest manifest, List<ContentValidationIssue> issues) {
    if (manifest.schemaVersion.isEmpty) {
      _addError(issues, 'MISSING_SCHEMA_VERSION', 'manifest',
          message: 'Schema version is missing.');
    } else if (!ContentSchemaConfig.isCompatible(manifest.schemaVersion)) {
      _addError(issues, 'UNSUPPORTED_SCHEMA_VERSION', 'manifest',
          message: 'Schema ${manifest.schemaVersion} is not supported by this app '
              '(expected ${ContentSchemaConfig.supportedSchemaVersion}).');
    }

    if (manifest.contentVersion.isEmpty) {
      _addError(issues, 'MISSING_CONTENT_VERSION', 'manifest',
          message: 'Content version is missing.');
    }
  }

  void _validateSubjects(ContentBundle bundle, List<ContentValidationIssue> issues) {
    final ids = <String>[];
    for (final subject in bundle.subjects) {
      if (subject.id.isEmpty) {
        _addError(issues, 'MISSING_ID', 'subjects', message: 'Subject has no id.');
        continue;
      }
      ids.add(subject.id);
      if (subject.names.isEmpty) {
        _addError(issues, 'MISSING_NAME', 'subjects', itemId: subject.id,
            message: 'Subject has no names.');
      }

      for (final chapterId in subject.chapterIds) {
        final chapter = _byId(bundle.chapters, chapterId);
        if (chapter == null) {
          _addError(issues, 'UNKNOWN_CHAPTER', 'subjects', itemId: subject.id,
              message: 'Subject references unknown chapter $chapterId.');
        } else if (chapter.subjectId != subject.id) {
          _addError(issues, 'MISMATCHED_CHAPTER', 'subjects', itemId: subject.id,
              message: 'Chapter $chapterId belongs to ${chapter.subjectId}, not ${subject.id}.');
        }
      }

      for (final lessonId in subject.lessonIds) {
        if (_byId(bundle.lessons, lessonId) == null) {
          _addError(issues, 'UNKNOWN_LESSON', 'subjects', itemId: subject.id,
              message: 'Subject references unknown lesson $lessonId.');
        }
      }
    }
    _reportDuplicates(issues, 'subjects', ids);
  }

  void _validateChapters(ContentBundle bundle, List<ContentValidationIssue> issues) {
    final ids = <String>[];
    for (final chapter in bundle.chapters) {
      if (chapter.id.isEmpty) {
        _addError(issues, 'MISSING_ID', 'chapters', message: 'Chapter has no id.');
        continue;
      }
      ids.add(chapter.id);
      if (chapter.names.isEmpty) {
        _addError(issues, 'MISSING_NAME', 'chapters', itemId: chapter.id,
            message: 'Chapter has no names.');
      }
      if (_byId(bundle.subjects, chapter.subjectId) == null) {
        _addError(issues, 'UNKNOWN_SUBJECT', 'chapters', itemId: chapter.id,
            message: 'Chapter references unknown subject ${chapter.subjectId}.');
      }

      for (final lessonId in chapter.lessonIds) {
        final lesson = _byId(bundle.lessons, lessonId);
        if (lesson == null) {
          _addError(issues, 'UNKNOWN_LESSON', 'chapters', itemId: chapter.id,
              message: 'Chapter references unknown lesson $lessonId.');
        } else if (lesson.chapterId != chapter.id) {
          _addError(issues, 'MISMATCHED_LESSON', 'chapters', itemId: chapter.id,
              message: 'Lesson $lessonId belongs to ${lesson.chapterId}, not ${chapter.id}.');
        }
      }
    }
    _reportDuplicates(issues, 'chapters', ids);
  }

  void _validateSources(ContentBundle bundle, List<ContentValidationIssue> issues) {
    final ids = <String>[];
    for (final source in bundle.sources) {
      if (source.id.isEmpty) {
        _addError(issues, 'MISSING_ID', 'sources', message: 'Source has no id.');
        continue;
      }
      ids.add(source.id);
      if (source.name.isEmpty) {
        _addError(issues, 'MISSING_NAME', 'sources', itemId: source.id,
            message: 'Source has no name.');
      }
      if (!source.verified) {
        _addWarning(issues, 'UNVERIFIED_SOURCE', 'sources', itemId: source.id,
            message: 'Source "${source.name}" is not verified; items citing it '
                'carry no provenance guarantee.');
      }
    }
    _reportDuplicates(issues, 'sources', ids);
  }

  void _validateLessons(ContentBundle bundle, List<ContentValidationIssue> issues) {
    final ids = <String>[];
    for (final lesson in bundle.lessons) {
      if (lesson.id.isEmpty) {
        _addError(issues, 'MISSING_ID', 'lessons', message: 'Lesson has no id.');
        continue;
      }
      ids.add(lesson.id);
      if (lesson.titles.isEmpty) {
        _addError(issues, 'MISSING_TITLE', 'lessons', itemId: lesson.id,
            message: 'Lesson has no titles.');
      }
      if (_byId(bundle.subjects, lesson.subjectId) == null) {
        _addError(issues, 'UNKNOWN_SUBJECT', 'lessons', itemId: lesson.id,
            message: 'Lesson references unknown subject ${lesson.subjectId}.');
      }
      final chapter = _byId(bundle.chapters, lesson.chapterId);
      if (chapter == null) {
        _addError(issues, 'UNKNOWN_CHAPTER', 'lessons', itemId: lesson.id,
            message: 'Lesson references unknown chapter ${lesson.chapterId}.');
      } else if (chapter.subjectId != lesson.subjectId) {
        _addError(issues, 'MISMATCHED_CHAPTER', 'lessons', itemId: lesson.id,
            message: 'Lesson subject ${lesson.subjectId} does not match its '
                'chapter ${chapter.subjectId}.');
      }
      if (_byId(bundle.sources, lesson.sourceId) == null) {
        _addError(issues, 'UNKNOWN_SOURCE', 'lessons', itemId: lesson.id,
            message: 'Lesson references unknown source ${lesson.sourceId}.');
      }
      if (lesson.estimatedMinutes < 0) {
        _addError(issues, 'INVALID_MINUTES', 'lessons', itemId: lesson.id,
            message: 'Estimated minutes cannot be negative.');
      }
      for (final conceptId in lesson.conceptIds) {
        if (_byId(bundle.concepts, conceptId) == null) {
          _addError(issues, 'UNKNOWN_CONCEPT', 'lessons', itemId: lesson.id,
              message: 'Lesson references unknown concept $conceptId.');
        }
      }
    }
    _reportDuplicates(issues, 'lessons', ids);
  }

  void _validateConcepts(ContentBundle bundle, List<ContentValidationIssue> issues) {
    final ids = <String>[];
    for (final concept in bundle.concepts) {
      if (concept.id.isEmpty) {
        _addError(issues, 'MISSING_ID', 'concepts', message: 'Concept has no id.');
        continue;
      }
      ids.add(concept.id);
      if (concept.name.isEmpty) {
        _addError(issues, 'MISSING_NAME', 'concepts', itemId: concept.id,
            message: 'Concept has no name.');
      }
      if (_byId(bundle.lessons, concept.lessonId) == null) {
        _addError(issues, 'UNKNOWN_LESSON', 'concepts', itemId: concept.id,
            message: 'Concept references unknown lesson ${concept.lessonId}.');
      }
      if (_byId(bundle.sources, concept.sourceId) == null) {
        _addError(issues, 'UNKNOWN_SOURCE', 'concepts', itemId: concept.id,
            message: 'Concept references unknown source ${concept.sourceId}.');
      }
    }
    _reportDuplicates(issues, 'concepts', ids);
  }

  void _validateQuestions(ContentBundle bundle, List<ContentValidationIssue> issues) {
    final ids = <String>[];
    for (final question in bundle.questions) {
      if (question.id.isEmpty) {
        _addError(issues, 'MISSING_ID', 'questions', message: 'Question has no id.');
        continue;
      }
      ids.add(question.id);
      if (question.prompt.isEmpty) {
        _addError(issues, 'MISSING_PROMPT', 'questions', itemId: question.id,
            message: 'Question has no prompt.');
      }
      if (_byId(bundle.subjects, question.subjectId) == null) {
        _addError(issues, 'UNKNOWN_SUBJECT', 'questions', itemId: question.id,
            message: 'Question references unknown subject ${question.subjectId}.');
      }
      final lesson = _byId(bundle.lessons, question.lessonId);
      if (lesson == null) {
        _addError(issues, 'UNKNOWN_LESSON', 'questions', itemId: question.id,
            message: 'Question references unknown lesson ${question.lessonId}.');
      }
      final concept = _byId(bundle.concepts, question.conceptId);
      if (concept == null) {
        _addError(issues, 'UNKNOWN_CONCEPT', 'questions', itemId: question.id,
            message: 'Question references unknown concept ${question.conceptId}.');
      } else if (lesson != null && concept.lessonId != lesson.id) {
        _addError(issues, 'MISMATCHED_CONCEPT', 'questions', itemId: question.id,
            message: 'Concept ${concept.id} belongs to lesson ${concept.lessonId}, '
                'not ${lesson.id}.');
      }
      if (_byId(bundle.sources, question.sourceId) == null) {
        _addError(issues, 'UNKNOWN_SOURCE', 'questions', itemId: question.id,
            message: 'Question references unknown source ${question.sourceId}.');
      }

      if (question.type == QuestionType.numeric) {
        if (question.numericAnswer == null) {
          _addError(issues, 'MISSING_NUMERIC_ANSWER', 'questions', itemId: question.id,
              message: 'Numeric question has no numeric answer.');
        }
      } else {
        if (question.options.length < 2) {
          _addError(issues, 'INVALID_OPTIONS', 'questions', itemId: question.id,
              message: 'Question needs at least two options.');
        }
        if (question.correctIndex == null) {
          _addError(issues, 'MISSING_CORRECT_ANSWER', 'questions', itemId: question.id,
              message: 'Question has no correct answer; it cannot be scored.');
        } else if (question.correctIndex! < 0 ||
            question.correctIndex! >= question.options.length) {
          _addError(issues, 'INVALID_CORRECT_INDEX', 'questions', itemId: question.id,
              message: 'Correct answer index ${question.correctIndex} is out of range.');
        }
      }

      if (question.difficulty < 1 || question.difficulty > 5) {
        _addWarning(issues, 'INVALID_DIFFICULTY', 'questions', itemId: question.id,
            message: 'Difficulty ${question.difficulty} is outside the 1..5 range.');
      }
    }
    _reportDuplicates(issues, 'questions', ids);
  }

  void _validateExams(ContentBundle bundle, List<ContentValidationIssue> issues) {
    final ids = <String>[];
    for (final exam in bundle.exams) {
      if (exam.id.isEmpty) {
        _addError(issues, 'MISSING_ID', 'exams', message: 'Exam has no id.');
        continue;
      }
      ids.add(exam.id);
      if (_byId(bundle.subjects, exam.subjectId) == null) {
        _addError(issues, 'UNKNOWN_SUBJECT', 'exams', itemId: exam.id,
            message: 'Exam references unknown subject ${exam.subjectId}.');
      }
      if (_byId(bundle.sources, exam.sourceId) == null) {
        _addError(issues, 'UNKNOWN_SOURCE', 'exams', itemId: exam.id,
            message: 'Exam references unknown source ${exam.sourceId}.');
      }
      if (exam.durationMinutes <= 0) {
        _addError(issues, 'INVALID_DURATION', 'exams', itemId: exam.id,
            message: 'Exam duration must be positive.');
      }
      if (exam.sections.isEmpty) {
        _addError(issues, 'EMPTY_EXAM', 'exams', itemId: exam.id,
            message: 'Exam has no sections.');
      }

      final sectionIds = <String>[];
      for (final section in exam.sections) {
        if (section.id.isEmpty) {
          _addError(issues, 'MISSING_ID', 'exams', itemId: exam.id,
              message: 'Exam section has no id.');
        } else {
          sectionIds.add(section.id);
        }
        for (final questionId in section.questionIds) {
          final question = _byId(bundle.questions, questionId);
          if (question == null) {
            _addError(issues, 'UNKNOWN_QUESTION', 'exams', itemId: exam.id,
                message: 'Exam section ${section.id} references unknown question $questionId.');
          } else if (question.subjectId != exam.subjectId) {
            _addError(issues, 'MISMATCHED_SUBJECT', 'exams', itemId: exam.id,
                message: 'Question $questionId belongs to ${question.subjectId}, '
                    'not ${exam.subjectId}.');
          }
        }
      }
      _reportDuplicates(issues, 'exams', sectionIds, itemLabel: 'section id');
    }
    _reportDuplicates(issues, 'exams', ids);
  }

  void _validateSolutions(ContentBundle bundle, List<ContentValidationIssue> issues) {
    final ids = <String>[];
    for (final solution in bundle.solutions) {
      if (solution.id.isEmpty) {
        _addError(issues, 'MISSING_ID', 'solutions', message: 'Solution has no id.');
        continue;
      }
      ids.add(solution.id);
      if (solution.examId.isEmpty) {
        _addError(issues, 'MISSING_EXAM', 'solutions', itemId: solution.id,
            message: 'Solution has no examId.');
      } else if (_byId(bundle.exams, solution.examId) == null) {
        _addError(issues, 'UNKNOWN_EXAM', 'solutions', itemId: solution.id,
            message: 'Solution references unknown exam ${solution.examId}.');
      }
      if (_byId(bundle.sources, solution.sourceId) == null) {
        _addError(issues, 'UNKNOWN_SOURCE', 'solutions', itemId: solution.id,
            message: 'Solution references unknown source ${solution.sourceId}.');
      }
    }
    _reportDuplicates(issues, 'solutions', ids);
  }

  void _validateTeachers(ContentBundle bundle, List<ContentValidationIssue> issues) {
    final ids = <String>[];
    for (final teacher in bundle.teachers) {
      if (teacher.id.isEmpty) {
        _addError(issues, 'MISSING_ID', 'teachers', message: 'Teacher has no id.');
        continue;
      }
      ids.add(teacher.id);
      if (teacher.name.isEmpty) {
        _addError(issues, 'MISSING_NAME', 'teachers', itemId: teacher.id,
            message: 'Teacher has no name.');
      }
    }
    _reportDuplicates(issues, 'teachers', ids);
    if (bundle.teachers.isEmpty) {
      _addWarning(issues, 'EMPTY_COLLECTION', 'teachers',
          message: 'No teachers defined.');
    }
  }

  void _validateVideos(ContentBundle bundle, List<ContentValidationIssue> issues) {
    final ids = <String>[];
    for (final video in bundle.videos) {
      if (video.id.isEmpty) {
        _addError(issues, 'MISSING_ID', 'videos', message: 'Video has no id.');
        continue;
      }
      ids.add(video.id);
      if (_byId(bundle.teachers, video.teacherId) == null) {
        _addError(issues, 'UNKNOWN_TEACHER', 'videos', itemId: video.id,
            message: 'Video references unknown teacher ${video.teacherId}.');
      }
      if (_byId(bundle.subjects, video.subjectId) == null) {
        _addError(issues, 'UNKNOWN_SUBJECT', 'videos', itemId: video.id,
            message: 'Video references unknown subject ${video.subjectId}.');
      }
      if (video.lessonId != null && _byId(bundle.lessons, video.lessonId!) == null) {
        _addError(issues, 'UNKNOWN_LESSON', 'videos', itemId: video.id,
            message: 'Video references unknown lesson ${video.lessonId}.');
      }
      if (video.platform.isEmpty || video.videoId.isEmpty || video.url.isEmpty) {
        _addError(issues, 'INVALID_VIDEO', 'videos', itemId: video.id,
            message: 'Video needs platform, videoId and url.');
      } else if (!_isHttpUrl(video.url)) {
        _addWarning(issues, 'INVALID_URL', 'videos', itemId: video.id,
            message: 'Video url is not an http(s) url.');
      }
    }
    _reportDuplicates(issues, 'videos', ids);
    if (bundle.videos.isEmpty) {
      _addWarning(issues, 'EMPTY_COLLECTION', 'videos', message: 'No videos defined.');
    }
  }

  void _validateWorksheets(ContentBundle bundle, List<ContentValidationIssue> issues) {
    final ids = <String>[];
    for (final worksheet in bundle.worksheets) {
      if (worksheet.id.isEmpty) {
        _addError(issues, 'MISSING_ID', 'worksheets', message: 'Worksheet has no id.');
        continue;
      }
      ids.add(worksheet.id);
      if (worksheet.title.isEmpty) {
        _addError(issues, 'MISSING_TITLE', 'worksheets', itemId: worksheet.id,
            message: 'Worksheet has no title.');
      }
      if (_byId(bundle.subjects, worksheet.subjectId) == null) {
        _addError(issues, 'UNKNOWN_SUBJECT', 'worksheets', itemId: worksheet.id,
            message: 'Worksheet references unknown subject ${worksheet.subjectId}.');
      }
      if (worksheet.lessonId != null && _byId(bundle.lessons, worksheet.lessonId!) == null) {
        _addError(issues, 'UNKNOWN_LESSON', 'worksheets', itemId: worksheet.id,
            message: 'Worksheet references unknown lesson ${worksheet.lessonId}.');
      }
      if (_byId(bundle.sources, worksheet.sourceId) == null) {
        _addError(issues, 'UNKNOWN_SOURCE', 'worksheets', itemId: worksheet.id,
            message: 'Worksheet references unknown source ${worksheet.sourceId}.');
      }
      if (worksheet.fileUrl.isEmpty) {
        _addError(issues, 'INVALID_FILE_URL', 'worksheets', itemId: worksheet.id,
            message: 'Worksheet has no file url.');
      } else if (!_isHttpUrl(worksheet.fileUrl)) {
        _addWarning(issues, 'INVALID_URL', 'worksheets', itemId: worksheet.id,
            message: 'Worksheet file url is not an http(s) url.');
      }
    }
    _reportDuplicates(issues, 'worksheets', ids);
    if (bundle.worksheets.isEmpty) {
      _addWarning(issues, 'EMPTY_COLLECTION', 'worksheets',
          message: 'No worksheets defined.');
    }
  }

  T? _byId<T extends Object>(List<T> items, String id) {
    for (final item in items) {
      if (id == _idOf(item)) {
        return item;
      }
    }
    return null;
  }

  String? _idOf(Object item) {
    if (item is Subject) return item.id;
    if (item is Chapter) return item.id;
    if (item is ContentSource) return item.id;
    if (item is Lesson) return item.id;
    if (item is Concept) return item.id;
    if (item is Question) return item.id;
    if (item is Exam) return item.id;
    if (item is ExamSolution) return item.id;
    if (item is Teacher) return item.id;
    if (item is VideoResource) return item.id;
    if (item is Worksheet) return item.id;
    return null;
  }

  void _reportDuplicates(
    List<ContentValidationIssue> issues,
    String collection,
    List<String> ids, {
    String itemLabel = 'duplicate id',
  }) {
    final seen = <String>{};
    for (final id in ids) {
      if (!seen.add(id)) {
        _addError(issues, 'DUPLICATE_ID', collection, itemId: id,
            message: '$itemLabel: $id.');
      }
    }
  }

  bool _isHttpUrl(String value) =>
      value.startsWith('https://') || value.startsWith('http://');

  void _addError(
    List<ContentValidationIssue> issues,
    String code,
    String collection, {
    String? itemId,
    String? message,
  }) {
    issues.add(ContentValidationIssue(
      severity: ContentIssueSeverity.error,
      code: code,
      collection: collection,
      itemId: itemId,
      message: message ?? code,
    ));
  }

  void _addWarning(
    List<ContentValidationIssue> issues,
    String code,
    String collection, {
    String? itemId,
    String? message,
  }) {
    issues.add(ContentValidationIssue(
      severity: ContentIssueSeverity.warning,
      code: code,
      collection: collection,
      itemId: itemId,
      message: message ?? code,
    ));
  }
}
