import 'exam.dart';
import 'question.dart';

/// In-memory state for one in-progress exam attempt.
class ExamSession {
  final Exam exam;

  /// The exam's questions in section/questionIds order.
  final List<Question> questions;

  final DateTime startedAt;

  /// questionId -> selected option index (unanswered questions are absent).
  final Map<String, int> answers;

  final Set<String> flaggedQuestionIds;

  int _currentIndex = 0;

  ExamSession({
    required this.exam,
    required this.questions,
    required this.startedAt,
    Map<String, int>? answers,
    Set<String>? flaggedQuestionIds,
  })  : answers = answers ?? <String, int>{},
        flaggedQuestionIds = flaggedQuestionIds ?? <String>{};

  int get currentIndex => _currentIndex;

  int get totalQuestions => questions.length;

  int get answeredCount => answers.length;

  bool get isLast => _currentIndex == questions.length - 1;

  bool get canGoPrevious => _currentIndex > 0;

  Question get currentQuestion => questions[_currentIndex];

  int? get currentSelection => answers[currentQuestion.id];

  bool get currentFlagged => flaggedQuestionIds.contains(currentQuestion.id);

  void goPrevious() {
    if (canGoPrevious) {
      _currentIndex--;
    }
  }

  void goNext() {
    if (!isLast) {
      _currentIndex++;
    }
  }

  /// Moves to an arbitrary question (used by resume and the navigator grid).
  void jumpTo(int index) {
    if (index >= 0 && index < questions.length) {
      _currentIndex = index;
    }
  }

  void selectAnswer(int index) {
    answers[currentQuestion.id] = index;
  }

  void toggleFlag() {
    final id = currentQuestion.id;
    if (!flaggedQuestionIds.add(id)) {
      flaggedQuestionIds.remove(id);
    }
  }
}
