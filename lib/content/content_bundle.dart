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
import 'validation/content_validation_result.dart';

/// A fully parsed content bundle: the manifest plus every collection.
class ContentBundle {
  const ContentBundle({
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

/// A content bundle together with the outcome of validating it.
class LoadedContent {
  const LoadedContent({required this.bundle, required this.validation});

  final ContentBundle bundle;
  final ContentValidationResult validation;

  bool get isValid => validation.isValid;
}
