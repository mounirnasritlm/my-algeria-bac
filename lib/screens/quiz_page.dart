import 'dart:async';

import 'package:flutter/material.dart';

import '../data/achievement_engine.dart';
import '../data/achievement_repository.dart';
import '../data/content_repository.dart';
import '../data/progress_repository.dart';
import '../models/question.dart';
import '../models/streak.dart';
import '../services/gamification_service.dart';
import '../services/streak_service.dart';
import 'quiz_result_page.dart';

class QuizPage extends StatefulWidget {
  final ContentRepository contentRepository;
  final String lessonId;

  const QuizPage({
    super.key,
    required this.contentRepository,
    required this.lessonId,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final ProgressRepository repository = ProgressRepository();
  final StreakService _streak = StreakService();

  /// Achievement + level evaluation after the quiz, so the result screen can
  /// celebrate level-ups and newly earned achievements. Lazily created so the
  /// widget stays cheap to construct and test.
  GamificationService? _gamification;

  /// Wall-clock start of this quiz, used to derive real study minutes for the
  /// streak. A distinct activity id per run prevents double counting.
  final DateTime _startedAt = DateTime.now();

  late List<Question> questions;

  int currentIndex = 0;
  int correctCount = 0;

  int? selectedIndex;
  bool answered = false;

  bool loading = true;

  double? score;

  String? _lessonTitle;

  Timer? _nextQuestionTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lesson = await widget.contentRepository.getLesson(widget.lessonId);
    final loaded = await widget.contentRepository
        .getQuestionsForLesson(widget.lessonId);

    final quizQuestions = loaded
        .where(
          (question) =>
              question.type == QuestionType.multipleChoice ||
              question.type == QuestionType.trueFalse,
        )
        .toList();

    if (!mounted) {
      return;
    }

    setState(() {
      questions = quizQuestions;
      _lessonTitle = lesson?.title;
      loading = false;
    });
  }

  @override
  void dispose() {
    _nextQuestionTimer?.cancel();
    super.dispose();
  }

  bool get isLastQuestion {
    return currentIndex == questions.length - 1;
  }

  bool get canSelectAnswer {
    return !answered && score == null;
  }

  void _selectAnswer(int index) {
    if (!canSelectAnswer) {
      return;
    }

    final question = questions[currentIndex];
    final isCorrect = question.correctIndex == index;

    setState(() {
      selectedIndex = index;
      answered = true;

      if (isCorrect) {
        correctCount++;
      }

      if (isLastQuestion) {
        score = correctCount * (100 / questions.length);
      }
    });

    unawaited(_recordAttempt(question: question, selectedIndex: index, isCorrect: isCorrect));

    if (!isLastQuestion) {
      _nextQuestionTimer = Timer(const Duration(seconds: 1), _nextQuestion);
    }
  }

  Future<void> _recordAttempt({
    required Question question,
    required int selectedIndex,
    required bool isCorrect,
  }) async {
    await repository.saveQuestionAttempt(
      questionId: question.id,
      lessonId: question.lessonId,
      conceptId: question.conceptId,
      selectedAnswer: selectedIndex,
      correctAnswer: question.correctIndex,
      isCorrect: isCorrect,
    );

    await repository.saveConceptAttempt(
      conceptId: question.conceptId,
      lessonId: question.lessonId,
      questionId: question.id,
      isCorrect: isCorrect,
      sourceType: 'quiz',
    );
  }

  void _nextQuestion() {
    if (!mounted) {
      return;
    }

    setState(() {
      currentIndex++;
      selectedIndex = null;
      answered = false;
    });
  }

  Future<void> _finishQuiz() async {
    // Score is set when the last question is answered, but the quiz can also
    // be ended early from the app bar, so derive it from the answers seen.
    final quizScore = score ?? correctCount * (100 / questions.length);

    await repository.saveLessonResult(
      lessonId: widget.lessonId,
      lessonTitle: _lessonTitle ?? '',
      questionsAnswered: questions.length,
      questionsCorrect: correctCount,
      xpEarned: quizScore.round(),
    );

    final recorded = await _streak.recordLearningActivity(
      activityId: 'quiz_${widget.lessonId}_${_startedAt.millisecondsSinceEpoch}',
      type: StreakActivityType.quiz,
      minutes: DateTime.now().difference(_startedAt).inMinutes,
    );

    final gamification = _gamification ??=
        GamificationService(
          progressRepository: repository,
          streakRepository: _streak.repository,
          achievementRepository: AchievementRepository(),
          contentRepository: widget.contentRepository,
        );

    final result = await gamification.evaluateAfterActivity(
      activity: CompletedActivity(
        type: AchievementActivityType.quiz,
        wasPerfect: questions.isNotEmpty && correctCount == questions.length,
      ),
      extraXp: recorded ? quizScore.round() : 0,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizResultPage(
          totalQuestions: questions.length,
          correctAnswers: correctCount,
          gamification: result,
        ),
      ),
    );
  }

  void _openScoreDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End quiz'),
        content: const Text(
          'You can end the quiz early and save your current score.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Continue'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _finishQuiz();
            },
            child: const Text('End quiz'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _lessonTitle ?? '',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: const Center(
          child: Text('No questions available yet.'),
        ),
      );
    }

    final question = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _lessonTitle ?? '',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (score == null) {
                _openScoreDialog();
              }
            },
            child: const Text('End quiz'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (currentIndex + 1) / questions.length,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${currentIndex + 1}/${questions.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            Text(
              question.prompt,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.4,
                  ),
            ),

            const SizedBox(height: 24),

            for (int index = 0;
                index < question.options.length;
                index++)
              _AnswerCard(
                index: index,
                text: question.options[index],
                selectedIndex: selectedIndex,
                correctIndex: question.correctIndex ?? -1,
                answered: answered,
                onTap: () => _selectAnswer(index),
              ),
          ],
        ),
      ),
      bottomNavigationBar: score == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _finishQuiz,
                    icon: const Icon(Icons.flag),
                    label: const Text('Finish and save'),
                  ),
                ),
              ),
            ),
    );
  }
}
class _AnswerCard extends StatelessWidget {
  final int index;
  final String text;
  final int? selectedIndex;
  final int correctIndex;
  final bool answered;
  final VoidCallback onTap;

  const _AnswerCard({
    required this.index,
    required this.text,
    required this.selectedIndex,
    required this.correctIndex,
    required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = selectedIndex == index;
    bool isCorrect = index == correctIndex;
    bool showCorrect = answered && isCorrect;
    bool showWrong = answered && isSelected && !isCorrect;

    Color? borderColor;
    Color? background;
    Color? letterColor;
    Widget? trailing;

    if (showCorrect) {
      borderColor = Colors.green;
      background = Colors.green.withValues(alpha: 0.10);
      letterColor = Colors.green;
      trailing = const Icon(
        Icons.check_circle,
        color: Colors.green,
      );
    } else if (showWrong) {
      borderColor = Colors.red;
      background = Colors.red.withValues(alpha: 0.10);
      letterColor = Colors.red;
      trailing = const Icon(
        Icons.cancel,
        color: Colors.red,
      );
    } else if (isSelected) {
      borderColor = Theme.of(context).colorScheme.primary;
      letterColor = Theme.of(context).colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: borderColor != null
            ? BorderSide(color: borderColor, width: 2)
            : BorderSide(color: Colors.grey.shade300),
      ),
      color: background,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: answered ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: letterColor?.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    color: letterColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
