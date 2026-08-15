import '../models/concept.dart';
import '../models/exam.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import '../models/resource.dart';
import '../models/subject.dart';
import '../models/teacher.dart';
import '../models/video.dart';

/// Source of all educational content for the app.
///
/// Screens depend on this interface, never on a concrete implementation.
/// Content can come from local JSON assets, a GitHub repository, a remote
/// API, or a database — the decision lives behind this seam.
abstract class ContentRepository {
  /// Version string of the loaded content bundle.
  Future<String> getContentVersion();

  Future<List<Subject>> getSubjects();

  Future<Subject?> getSubject(String subjectId);

  Future<List<Lesson>> getLessonsForSubject(String subjectId);

  Future<Lesson?> getLesson(String lessonId);

  Future<List<Concept>> getConceptsForLesson(String lessonId);

  Future<Concept?> getConcept(String conceptId);

  Future<List<Question>> getQuestionsForLesson(String lessonId);

  Future<List<Question>> getQuestionsForConcept(String conceptId);

  Future<List<Exam>> getExams();

  Future<Exam?> getExam(String examId);

  /// The questions of one exam, in section/questionIds order.
  Future<List<Question>> getQuestionsForExam(String examId);

  Future<List<Resource>> getResourcesForSubject(String subjectId);

  Future<List<Teacher>> getTeachers();

  Future<List<Video>> getVideos();
}
