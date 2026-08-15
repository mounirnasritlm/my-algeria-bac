import 'dart:async';

import 'package:flutter/material.dart';

import '../data/achievement_engine.dart';
import '../data/achievement_repository.dart';
import '../data/content_repository.dart';
import '../data/exam_scoring.dart';
import '../data/exam_session_repository.dart';
import '../data/progress_repository.dart';
import '../data/streak_engine.dart';
import '../models/exam.dart';
import '../models/exam_attempt.dart';
import '../models/exam_session.dart';
import '../models/question.dart';
import '../models/saved_exam_session.dart';
import '../models/streak.dart';
import '../services/gamification_service.dart';
import '../services/streak_service.dart';
import 'exam_report_page.dart';

/// BAC Boss: a serious, timed full exam session. No gamified interruptions.
///
/// The session is autosaved as the student answers, so closing the app
/// mid-paper lets them resume from where they left off (time still counted
/// against the clock). On reopen after the clock ran out, the exam is
/// submitted automatically.
class ExamSessionPage extends StatefulWidget {
  final ContentRepository contentRepository;

  final String examId;

  /// Injectable for tests; defaults to the real repositories.
  final ProgressRepository? progressRepository;

  final ExamSessionRepository? sessionRepository;

  /// Injectable for tests; defaults to the real service.
  final StreakService? streakService;

  /// Injectable for tests; defaults to the real service. The default is
  /// backed by the real repositories, so production never needs to pass it.
  final GamificationService? gamificationService;

  const ExamSessionPage({
    super.key,
    required this.contentRepository,
    required this.examId,
    this.progressRepository,
    this.sessionRepository,
    this.streakService,
    this.gamificationService,
  });

  @override
  State<ExamSessionPage> createState() => _ExamSessionPageState();
}

class _ExamSessionPageState extends State<ExamSessionPage> {
  late final ProgressRepository _progress =
      widget.progressRepository ?? ProgressRepository();
  late final ExamSessionRepository _sessions =
      widget.sessionRepository ?? ExamSessionRepository();
  late final StreakService _streak =
      widget.streakService ?? StreakService();

  /// Achievement/level evaluation after submission, passed to the report.
  GamificationService? _gamification;

  Exam? _exam;
  List<Question> _questions = const [];
  bool _loading = true;
  String? _subjectName;

  /// A saved in-progress session for this exam (shown on the intro screen).
  SavedExamSession? _resumable;

  ExamSession? _session;

  /// The persisted session id backing [_session] (autosave target).
  String? _sessionId;

  late int _remainingSeconds;

  Timer? _ticker;

  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final exam = await widget.contentRepository.getExam(widget.examId);
    final questions =
        await widget.contentRepository.getQuestionsForExam(widget.examId);

    String? subjectName;
    if (exam != null) {
      final subject = await widget.contentRepository.getSubject(exam.subjectId);
      subjectName = subject?.name;
    }

    final resumable = await _sessions.getInProgressSession(widget.examId);

    if (!mounted) {
      return;
    }

    // A previous attempt whose clock ran out while the app was closed:
    // submit it immediately and show the report.
    if (exam != null &&
        questions.isNotEmpty &&
        resumable != null &&
        sessionExpiredFor(
          startedAt: resumable.startedAt,
          durationSeconds: exam.durationMinutes * 60,
          now: DateTime.now(),
        )) {
      _exam = exam;
      _questions = questions;
      _session = _restoreSession(resumable, exam, questions);
      _sessionId = resumable.id;
      _remainingSeconds = 0;
      _submitted = true;

      await _sessions.markSubmitted(sessionId: resumable.id);
      await _finish(autoSubmitted: true);
      return;
    }

    setState(() {
      _exam = exam;
      _questions = questions;
      _resumable = resumable;
      _subjectName = subjectName;
      _loading = false;
    });
  }

  ExamSession _restoreSession(
    SavedExamSession saved,
    Exam exam,
    List<Question> questions,
  ) {
    final session = ExamSession(
      exam: exam,
      questions: questions,
      startedAt: saved.startedAt,
      answers: saved.answers,
      flaggedQuestionIds: saved.flaggedQuestionIds,
    );
    session.jumpTo(saved.currentIndex);
    return session;
  }

  Future<void> _startOrResume() async {
    final exam = _exam;
    if (exam == null || _questions.isEmpty || _submitted) {
      return;
    }

    final resumable = _resumable;
    final now = DateTime.now();

    String sessionId;
    ExamSession session;
    int remaining;

    if (resumable != null) {
      session = _restoreSession(resumable, exam, _questions);
      sessionId = resumable.id;
      remaining = remainingSecondsFor(
        startedAt: session.startedAt,
        durationSeconds: exam.durationMinutes * 60,
        now: now,
      );
    } else {
      final created = await _sessions.createSession(
        examId: exam.id,
        durationSeconds: exam.durationMinutes * 60,
      );
      sessionId = created.id;
      session = ExamSession(
        exam: exam,
        questions: _questions,
        startedAt: created.startedAt,
      );
      remaining = exam.durationMinutes * 60;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _session = session;
      _sessionId = sessionId;
      _remainingSeconds = remaining;
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer timer) {
    if (_remainingSeconds <= 0) {
      _autoSubmit();
      return;
    }

    setState(() {
      _remainingSeconds--;
    });

    if (_remainingSeconds <= 0) {
      _autoSubmit();
    }
  }

  void _autoSubmit() {
    if (_submitted) {
      return;
    }

    _submitted = true;
    _ticker?.cancel();
    _finish(autoSubmitted: true);
  }

  void _confirmSubmit() {
    if (_submitted || _session == null) {
      return;
    }

    final session = _session!;
    final unanswered = session.totalQuestions - session.answeredCount;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit exam?'),
        content: Text(
          unanswered > 0
              ? 'You have $unanswered unanswered question'
                  '${unanswered == 1 ? '' : 's'}. '
                  'Unanswered questions score zero.'
              : 'You answered every question. Submit your exam now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep working'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _submitted = true;
              _ticker?.cancel();
              _finish(autoSubmitted: false);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _finish({required bool autoSubmitted}) async {
    final session = _session;
    if (session == null || _exam == null) {
      return;
    }

    final sessionId = _sessionId;
    if (sessionId != null) {
      await _sessions.markSubmitted(sessionId: sessionId);
    }

    final attempt = buildExamAttempt(
      session: session,
      timeUsedSeconds: _exam!.durationMinutes * 60 - _remainingSeconds,
    );

    await _recordAttempts(attempt);

    // A completed BAC Boss is a real, qualifying streak activity — recorded
    // only once per session, and only when the exam actually finished.
    final recorded = await _streak.recordLearningActivity(
      activityId: 'bac_boss_$sessionId',
      type: StreakActivityType.bacBoss,
      minutes: attempt.timeUsedSeconds ~/ 60,
    );

    final gamification = _gamification ??=
        widget.gamificationService ??
        GamificationService(
          progressRepository: _progress,
          streakRepository: _streak.repository,
          achievementRepository: AchievementRepository(),
          contentRepository: widget.contentRepository,
        );

    final result = await gamification.evaluateAfterActivity(
      activity: CompletedActivity(
        type: AchievementActivityType.exam,
        wasPerfect: attempt.correctCount == attempt.totalQuestions,
        subjectId: _exam!.subjectId,
      ),
      extraXp: recorded ? calculateStreakXp(type: StreakActivityType.bacBoss, minutes: attempt.timeUsedSeconds ~/ 60) : 0,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ExamReportPage(
          contentRepository: widget.contentRepository,
          attempt: attempt,
          autoSubmitted: autoSubmitted,
          gamification: result,
        ),
      ),
    );
  }

  Future<void> _recordAttempts(ExamAttempt attempt) async {
    await _progress.saveExamAttempt(
      examId: attempt.examId,
      scoreOn20: attempt.scoreOn20,
      correctCount: attempt.correctCount,
      totalQuestions: attempt.totalQuestions,
      timeUsedSeconds: attempt.timeUsedSeconds,
    );

    for (final result in attempt.results) {
      final selected = result.selectedIndex;
      if (selected == null) {
        continue;
      }

      final question = result.question;

      await _progress.saveQuestionAttempt(
        questionId: question.id,
        lessonId: question.lessonId,
        conceptId: question.conceptId,
        selectedAnswer: selected,
        correctAnswer: question.correctIndex,
        isCorrect: result.isCorrect,
      );

      await _progress.saveConceptAttempt(
        conceptId: question.conceptId,
        lessonId: question.lessonId,
        questionId: question.id,
        isCorrect: result.isCorrect,
        sourceType: 'bac_boss',
      );
    }
  }

  // ---------------------------------------------------------------------
  // Autosave + interaction.
  // ---------------------------------------------------------------------

  void _selectAnswer(int index) {
    final session = _session;
    if (session == null || _submitted) {
      return;
    }

    setState(() {
      session.selectAnswer(index);
    });

    _sessions.saveAnswer(
      sessionId: _sessionId!,
      questionId: session.currentQuestion.id,
      selectedIndex: index,
    );
  }

  void _toggleFlag() {
    final session = _session;
    if (session == null) {
      return;
    }

    setState(() {
      session.toggleFlag();
    });

    _sessions.setFlags(
      sessionId: _sessionId!,
      flaggedQuestionIds: session.flaggedQuestionIds,
    );
  }

  void _goTo(int index) {
    final session = _session;
    if (session == null) {
      return;
    }

    setState(() {
      session.jumpTo(index);
    });

    _sessions.setCurrentIndex(sessionId: _sessionId!, index: index);
  }

  void _openNavigator() {
    final session = _session;
    if (session == null) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _QuestionNavigatorSheet(
        questions: session.questions,
        answers: session.answers,
        flagged: session.flaggedQuestionIds,
        currentIndex: session.currentIndex,
        onJump: (index) {
          Navigator.of(context).pop();
          _goTo(index);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Build.
  // ---------------------------------------------------------------------

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    String two(int value) => value.toString().padLeft(2, '0');

    return hours > 0
        ? '${two(hours)}:${two(minutes)}:${two(secs)}'
        : '${two(minutes)}:${two(secs)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_exam == null) {
      return const Scaffold(
        body: Center(child: Text('Exam not found.')),
      );
    }

    if (_questions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('This exam has no questions yet.')),
      );
    }

    final session = _session;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('BAC Boss')),
        body: _BossIntro(
          subjectName: _subjectName,
          durationMinutes: _exam!.durationMinutes,
          questionCount: _questions.length,
          resumable: _resumable,
          onStart: _startOrResume,
        ),
      );
    }

    final question = session.currentQuestion;
    final section = _sectionFor(question.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BAC Boss'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _formatTime(_remainingSeconds),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: _remainingSeconds <= 300
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: session.totalQuestions == 0
                  ? 0
                  : session.answeredCount / session.totalQuestions,
              minHeight: 5,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (section != null) ...[
                    Text(
                      section.title,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Question ${session.currentIndex + 1} of '
                          '${session.totalQuestions}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      Text(
                        '${session.answeredCount}/${session.totalQuestions} answered',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        question.prompt,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              height: 1.4,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < question.options.length; i++)
                    _ExamOptionCard(
                      label: String.fromCharCode(65 + i),
                      text: question.options[i],
                      selected: session.currentSelection == i,
                      onTap: () => _selectAnswer(i),
                    ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _toggleFlag,
                      icon: Icon(
                        session.currentFlagged
                            ? Icons.flag
                            : Icons.flag_outlined,
                        size: 18,
                        color: session.currentFlagged ? Colors.orange : null,
                      ),
                      label: Text(session.currentFlagged ? 'Flagged' : 'Flag'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: _openNavigator,
                    icon: const Icon(Icons.grid_view_outlined),
                    label: const Text('Question navigator'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          session.canGoPrevious ? () => _goTo(session.currentIndex - 1) : null,
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: session.isLast
                        ? FilledButton(
                            onPressed: _confirmSubmit,
                            child: const Text('Submit exam'),
                          )
                        : FilledButton(
                            onPressed: () => _goTo(session.currentIndex + 1),
                            child: const Text('Next'),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ExamSection? _sectionFor(String questionId) {
    for (final section in _exam!.sections) {
      if (section.questionIds.contains(questionId)) {
        return section;
      }
    }
    return null;
  }
}

class _BossIntro extends StatelessWidget {
  final String? subjectName;
  final int durationMinutes;
  final int questionCount;
  final SavedExamSession? resumable;
  final VoidCallback onStart;

  const _BossIntro({
    required this.subjectName,
    required this.durationMinutes,
    required this.questionCount,
    required this.resumable,
    required this.onStart,
  });

  String get _durationText {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    return hours > 0
        ? '${hours}h ${minutes == 0 ? '' : '${minutes}m'}'.trim()
        : '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final resumable = this.resumable;
    final remaining = resumable == null
        ? null
        : remainingSecondsFor(
            startedAt: resumable.startedAt,
            durationSeconds: resumable.durationSeconds,
            now: DateTime.now(),
          );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 20),
          const Center(
            child: Icon(
              Icons.shield_outlined,
              size: 64,
              color: Color(0xFF5B21B6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'BAC BOSS',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subjectName ?? 'Full paper',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _BossInfoRow(
                    icon: Icons.timer_outlined,
                    label: 'Time',
                    value: _durationText,
                  ),
                  const SizedBox(height: 14),
                  _BossInfoRow(
                    icon: Icons.quiz_outlined,
                    label: 'Questions',
                    value: '$questionCount',
                  ),
                  const SizedBox(height: 14),
                  const _BossInfoRow(
                    icon: Icons.block,
                    label: 'Hints',
                    value: 'Disabled',
                  ),
                  const SizedBox(height: 14),
                  const _BossInfoRow(
                    icon: Icons.notifications_off,
                    label: 'Distractions',
                    value: 'Disabled',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'Treat this like a real exam. No hints, no XP popups, '
              'no interruptions. Manage the clock and review your '
              'answers before submitting.',
              style: TextStyle(fontWeight: FontWeight.w600, height: 1.45),
            ),
          ),
          if (resumable != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: 0.08,
                    ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.autorenew,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You have an unfinished attempt'
                      '${remaining == null ? '' : ' — $remaining seconds left'}.'
                      '\nResuming keeps your answers and the clock.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: onStart,
              child: Text(resumable != null ? 'Resume exam' : 'Enter the Boss'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BossInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BossInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _QuestionNavigatorSheet extends StatelessWidget {
  final List<Question> questions;
  final Map<String, int> answers;
  final Set<String> flagged;
  final int currentIndex;
  final ValueChanged<int> onJump;

  const _QuestionNavigatorSheet({
    required this.questions,
    required this.answers,
    required this.flagged,
    required this.currentIndex,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Question navigator',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 14,
              children: const [
                _LegendDot(color: Colors.grey, label: 'Unanswered'),
                _LegendDot(color: Color(0xFF2563EB), label: 'Answered'),
                _LegendDot(color: Color(0xFFF59E0B), label: 'Flagged'),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final question = questions[index];
                final isAnswered = answers.containsKey(question.id);
                final isFlagged = flagged.contains(question.id);
                final isCurrent = index == currentIndex;

                Color background;
                if (isFlagged) {
                  background = Colors.orange.withValues(alpha: 0.18);
                } else if (isAnswered) {
                  background =
                      const Color(0xFF2563EB).withValues(alpha: 0.14);
                } else {
                  background = Colors.grey.withValues(alpha: 0.12);
                }

                return InkWell(
                  onTap: () => onJump(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(12),
                      border: isCurrent
                          ? Border.all(
                              width: 2,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _ExamOptionCard extends StatelessWidget {
  final String label;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _ExamOptionCard({
    required this.label,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.10)
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: selected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: selected ? colorScheme.onPrimary : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(height: 1.35),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, size: 18, color: colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
