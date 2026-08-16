import '../models/chapter.dart';
import '../models/concept.dart';
import '../models/content_source.dart';
import '../models/exam.dart';
import '../models/exam_solution.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import '../models/subject.dart';
import '../models/teacher.dart';
import '../models/video_resource.dart';
import '../models/worksheet.dart';

/// Source of all educational content for the app.
///
/// Screens depend on this interface, never on a concrete implementation.
/// Content can come from local JSON assets, a GitHub repository, a remote
/// API, or a database — the decision lives behind this seam. A GitHub repo is
/// the planned production source; the versioned manifest is the contract
/// between the repo and this app.
abstract class ContentRepository {
  /// Version string of the loaded content bundle.
  Future<String> getContentVersion();

  Future<List<Subject>> getSubjects();

  Future<Subject?> getSubject(String subjectId);

  Future<List<Chapter>> getChaptersForSubject(String subjectId);

  Future<Chapter?> getChapter(String chapterId);

  Future<List<Lesson>> getLessonsForChapter(String chapterId);

  Future<Lesson?> getLesson(String lessonId);

  Future<List<Concept>> getConceptsForLesson(String lessonId);

  /// Kept for concept → name/lesson resolution used by weak-points, exam
  /// reports, and the comeback planner.
  Future<Concept?> getConcept(String conceptId);

  Future<List<Question>> getQuestionsForLesson(String lessonId);

  Future<List<Question>> getQuestionsForConcept(String conceptId);

  Future<List<Exam>> getExams();

  Future<Exam?> getExam(String examId);

  /// The questions of one exam, in section/questionIds order. Used by the
  /// BAC Boss session.
  Future<List<Question>> getQuestionsForExam(String examId);

  Future<ExamSolution?> getExamSolution(String examId);

  Future<List<ContentSource>> getSources();

  Future<ContentSource?> getSource(String sourceId);

  Future<List<Teacher>> getTeachers();

  Future<Teacher?> getTeacher(String teacherId);

  Future<List<VideoResource>> getVideosForLesson(String lessonId);

  Future<List<Worksheet>> getWorksheetsForLesson(String lessonId);
}
