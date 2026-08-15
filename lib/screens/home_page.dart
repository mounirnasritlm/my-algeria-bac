import 'package:flutter/material.dart';

import '../data/campaign_engine.dart';
import '../data/content_repository.dart';
import '../data/progress_repository.dart';
import '../data/streak_repository.dart';
import '../models/bac_campaign.dart';
import '../models/concept_mastery.dart';
import '../models/exam.dart';
import '../models/subject.dart';
import 'bac_page.dart';
import 'mission_page.dart';
import 'streak_page.dart';
import 'study_plan_page.dart';
import 'weak_points_page.dart';
/// BAC Command Center: the countdown, today's mission, real streak/XP, and a
/// per-subject BAC profile. Every number is derived from real activity.
class HomePage extends StatefulWidget {
  final ContentRepository contentRepository;

  /// Called to switch to a bottom navigation tab (mission actions).
  final ValueChanged<int>? onNavigateToTab;

  const HomePage({
    super.key,
    required this.contentRepository,
    this.onNavigateToTab,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProgressRepository _progress = ProgressRepository();

  bool _loading = true;

  BacCountdown? _countdown;
  DailyMission? _mission;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _xp = 0;
  int _questionsAnswered = 0;
  double _overallAccuracy = 0;
  int _attentionConcepts = 0;
  List<_SubjectBar> _subjectBars = const [];
  List<Exam> _exams = const [];
  DateTime? _bacDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = DateTime.now();

    final bacDate = await _progress.getBacDate();
    final mastery = await _progress.getAllConceptMastery();
    final activity = await _progress.getDailyActivity(today);
    final streakState = await StreakRepository().getState();

    final subjects = await widget.contentRepository.getSubjects();
    final exams = await widget.contentRepository.getExams();

    final lessonSubject = await _lessonSubjectMap(subjects);

    final subjectAgg = _subjectAggregates(mastery, lessonSubject);
    final subjectBars = <_SubjectBar>[];

    for (final entry in subjectAgg.entries) {
      Subject? subject;
      for (final candidate in subjects) {
        if (candidate.id == entry.key) {
          subject = candidate;
          break;
        }
      }

      final attempts = entry.value.attempts;
      if (attempts == 0 || subject == null) {
        continue;
      }

      subjectBars.add(
        _SubjectBar(
          name: subject.name,
          accuracy: entry.value.correct / attempts,
        ),
      );
    }

    subjectBars.sort((a, b) => b.accuracy.compareTo(a.accuracy));

    final attempted = mastery.where((m) => m.attempts > 0).toList();
    final totalAttempts =
        attempted.fold(0, (sum, m) => sum + m.attempts);
    final totalCorrect = attempted.fold(0, (sum, m) => sum + m.correct);

    final questionsAnswered = await _progress.getTotalQuestionsAnswered();

    final mission = missionFor(
      today: today,
      mastery: mastery,
      activity: activity,
    );

    // Award once per day, guarded by the completion date, so the XP chip
    // reflects a finished mission right after a refresh.
    await _progress.awardMissionXp(mission, today);

    final xp = await _progress.getTotalXp();

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      _bacDate = bacDate;
      _countdown = bacDate == null
          ? null
          : countdownFor(bacDate: bacDate, today: today);
      _mission = mission;
      _currentStreak = streakState.currentStreak;
      _longestStreak = streakState.longestStreak;
      _questionsAnswered = questionsAnswered;
      _overallAccuracy =
          totalAttempts == 0 ? 0 : totalCorrect / totalAttempts;
      _attentionConcepts = attempted
          .where((m) => m.isWeak)
          .length;
      _subjectBars = subjectBars;
      _exams = exams;
      _xp = xp;
    });
  }

  Future<Map<String, String>> _lessonSubjectMap(
    List<Subject> subjects,
  ) async {
    final map = <String, String>{};

    for (final subject in subjects) {
      final lessons = await widget.contentRepository
          .getLessonsForSubject(subject.id);

      for (final lesson in lessons) {
        map[lesson.id] = subject.id;
      }
    }

    return map;
  }

  Map<String, _SubjectAggregate> _subjectAggregates(
    List<ConceptMastery> mastery,
    Map<String, String> lessonSubject,
  ) {
    final map = <String, _SubjectAggregate>{};

    for (final item in mastery) {
      final subjectId = lessonSubject[item.lessonId];
      if (subjectId == null) {
        continue;
      }

      final agg = map.putIfAbsent(
        subjectId,
        () => _SubjectAggregate(),
      );
      agg.attempts += item.attempts;
      agg.correct += item.correct;
    }

    return map;
  }

  void _openWeakPoints() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WeakPointsPage(
          contentRepository: widget.contentRepository,
        ),
      ),
    );
  }

  void _openMissionPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MissionPage(
          contentRepository: widget.contentRepository,
          onNavigateToTab: widget.onNavigateToTab,
        ),
      ),
    );
  }

  void _openStudyPlan() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudyPlanPage(
          contentRepository: widget.contentRepository,
        ),
      ),
    );
  }

  void _openStreak() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const StreakPage(),
      ),
    );
  }

  Future<void> _pickBacDate() async {
    final now = DateTime.now();
    final defaultDate = DateTime(now.year + 1, 6, 10);

    final picked = await showDatePicker(
      context: context,
      initialDate: _bacDate ?? defaultDate,
      firstDate: DateTime(now.year, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );

    if (picked == null) {
      return;
    }

    await _progress.saveBacDate(picked);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  _header(context),

                  const SizedBox(height: 20),

                  _countdownCard(context),

                  const SizedBox(height: 20),

                  if (_mission != null)
                    _missionCard(context, _mission!),

                  const SizedBox(height: 20),

                  _studyPlanCard(context),

                  const SizedBox(height: 20),

                  _progressCard(context),

                  const SizedBox(height: 24),

                  _bacProfile(context),

                  if (_exams.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _examBattleCard(context),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سلام 👋',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ready for BAC?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
        _streakChip(),
        const SizedBox(width: 8),
        _xpChip(),
      ],
    );
  }

  Widget _streakChip() {
    return GestureDetector(
      onTap: _openStreak,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Color(0xFFF97316),
              size: 18,
            ),
            const SizedBox(width: 5),
            Text(
              '$_currentStreak',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _xpChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF7FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.stars_outlined,
            color: Color(0xFF2563EB),
            size: 18,
          ),
          const SizedBox(width: 5),
          Text(
            '$_xp XP',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _countdownCard(BuildContext context) {
    final countdown = _countdown;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: countdown == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BAC COUNTDOWN',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Set your BAC exam date\nto start the countdown.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _pickBacDate,
                  child: const Text('Set BAC date'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'BAC COUNTDOWN',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: _pickBacDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          _bacDate == null
                              ? 'Set date'
                              : '${_bacDate!.year}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '${countdown.daysRemaining} DAYS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${countdown.weeksRemaining} weeks • '
                  '${countdown.hoursRemaining} hours',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    countdown.season.label.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _missionCard(BuildContext context, DailyMission mission) {
    final fraction = mission.target == 0
        ? 0.0
        : (mission.progress / mission.target).clamp(0.0, 1.0).toDouble();

    return GestureDetector(
      onTap: _openMissionPage,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.flag, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "TODAY'S MISSION",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (mission.isComplete)
                  const Icon(Icons.check_circle, color: Colors.white),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              mission.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mission.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${mission.progress} / ${mission.target}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.bolt, color: Color(0xFFFDE047), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '+${mission.rewardXp} XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _studyPlanCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _openStudyPlan,
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              Text('🧠', style: TextStyle(fontSize: 30)),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Study Plan',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'A plan built around what you need to improve.',
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressCard(BuildContext context) {    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Overall accuracy',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${(_overallAccuracy * 100).round()}%',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: _overallAccuracy,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(value: '$_questionsAnswered', label: 'Questions'),
                _StatItem(value: '$_longestStreak', label: 'Longest streak'),
                _StatItem(
                  value: '$_attentionConcepts',
                  label: 'Weak concepts',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bacProfile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your BAC profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        if (_subjectBars.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Answer some questions to see your per-subject profile.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final bar in _subjectBars) ...[
                    _SubjectBarRow(bar: bar),
                    if (bar != _subjectBars.last) const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _openWeakPoints,
          icon: const Icon(Icons.warning_amber_outlined),
          label: Text(
            _attentionConcepts == 0
                ? 'No weak concepts — keep it up!'
                : '$_attentionConcepts concepts need attention',
          ),
        ),
      ],
    );
  }

  Widget _examBattleCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sports_martial_arts, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text(
                'BAC BOSS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Can you survive a full paper?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_exams.length} '
            '${_exams.length == 1 ? 'exam' : 'exams'} available • timed • '
            'real conditions',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF5B21B6),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BacPage(
                      contentRepository: widget.contentRepository,
                    ),
                  ),
                );
              },
              child: const Text('Enter the Arena'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectAggregate {
  int attempts = 0;
  int correct = 0;
}

class _SubjectBar {
  final String name;
  final double accuracy;

  const _SubjectBar({required this.name, required this.accuracy});
}

class _SubjectBarRow extends StatelessWidget {
  final _SubjectBar bar;

  const _SubjectBarRow({required this.bar});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            bar.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: bar.accuracy,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text(
            '${(bar.accuracy * 100).round()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
