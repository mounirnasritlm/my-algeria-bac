import 'package:flutter/material.dart';

import '../config/app_language_context.dart';
import '../data/comeback_engine.dart';
import '../data/content_repository.dart';
import '../data/exam_scoring.dart';
import '../data/progress_repository.dart';
import '../l10n/app_strings.dart';
import '../l10n/engine_strings.dart';
import '../models/comeback.dart';
import '../models/exam_attempt.dart';
import '../services/gamification_service.dart';
import 'comeback_page.dart';
import 'exam_session_page.dart';

/// Report for a submitted exam: score /20, time management, and strong/weak
/// concepts from this attempt.
class ExamReportPage extends StatefulWidget {
  final ContentRepository contentRepository;

  final ExamAttempt attempt;

  final bool autoSubmitted;

  /// Achievement/level outcome of the finished exam, when one was computed.
  final GamificationResult? gamification;

  const ExamReportPage({
    super.key,
    required this.contentRepository,
    required this.attempt,
    required this.autoSubmitted,
    this.gamification,
  });

  @override
  State<ExamReportPage> createState() => _ExamReportPageState();
}

class _ExamReportPageState extends State<ExamReportPage> {
  final Map<String, String> _conceptNames = {};
  final Map<String, String> _lessonIds = {};
  final ProgressRepository _progress = ProgressRepository();
  double? _previousScore;

  @override
  void initState() {
    super.initState();
    _loadConceptNames();
    _loadPreviousScore();
  }

  Future<void> _loadPreviousScore() async {
    final history =
        await _progress.getExamAttemptHistory(widget.attempt.examId);

    // The current attempt was just recorded, so the previous one (if any)
    // is the second row.
    if (history.length > 1) {
      _previousScore = history[1].scoreOn20;
    }
  }

  Future<void> _loadConceptNames() async {
    for (final concept in widget.attempt.conceptResults) {
      final loaded =
          await widget.contentRepository.getConcept(concept.conceptId);

      _conceptNames[concept.conceptId] = loaded?.name ?? concept.conceptId;
      if (loaded?.lessonId != null) {
        _lessonIds[concept.conceptId] = loaded!.lessonId;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  String get _formattedScore {
    final score = widget.attempt.scoreOn20;
    return score == score.roundToDouble()
        ? score.toStringAsFixed(0)
        : score.toStringAsFixed(1);
  }

  String get _formattedTime {
    final seconds = widget.attempt.timeUsedSeconds;
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
    final attempt = widget.attempt;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t(context, 'exam_report')),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.autoSubmitted)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppStrings.t(context, 'time_ran_out'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Center(
              child: Column(
                children: [
                  Text(
                    _formattedScore,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  Text(
                    AppStrings.t(context, 'out_of_20'),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.t(context, 'correct_of_total', args: [
                      attempt.correctCount,
                      attempt.totalQuestions,
                    ]),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (widget.gamification != null)
              _ReportGamification(result: widget.gamification!),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: AppStrings.t(context, 'time_used'),
                    value: _formattedTime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: AppStrings.t(context, 'time_management'),
                    value: timeManagementLabelFor(
                      timeManagementLabel(
                        timeUsedSeconds: attempt.timeUsedSeconds,
                        durationMinutes: attempt.durationMinutes,
                      ),
                      appLanguageOf(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.t(context, 'score_disclaimer'),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.t(context, 'strong_concepts'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            if (attempt.conceptResults.where((c) => c.isStrength).isEmpty)
              _EmptyHint(text: AppStrings.t(context, 'nothing_to_highlight')),
            for (final concept
                in attempt.conceptResults.where((c) => c.isStrength))
              _ConceptTile(
                icon: Icons.check_circle_outline,
                color: Colors.green,
                name: _conceptNames[concept.conceptId] ?? concept.conceptId,
                detail: AppStrings.t(context, 'percent_correct',
                    args: [_percent(concept.accuracy)]),
              ),
            const SizedBox(height: 24),
            Text(
              AppStrings.t(context, 'weak_concepts'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            if (attempt.conceptResults.where((c) => c.isWeakness).isEmpty)
              _EmptyHint(
                text: AppStrings.t(context, 'no_weak_concepts_attempt'),
              ),
            for (final concept
                in attempt.conceptResults.where((c) => c.isWeakness))
              _ConceptTile(
                icon: Icons.error_outline,
                color: Colors.orange,
                name: _conceptNames[concept.conceptId] ?? concept.conceptId,
                detail: AppStrings.t(context, 'percent_correct',
                    args: [_percent(concept.accuracy)]),
              ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => ExamSessionPage(
                              contentRepository: widget.contentRepository,
                              examId: widget.attempt.examId,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        AppStrings.t(context, 'rematch'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      child: Text(AppStrings.t(context, 'back_to_practice')),
                    ),
                  ),
                ],
              ),
            ),
            if (isPassingScore(attempt.scoreOn20)) const SizedBox(height: 12),
            if (isPassingScore(attempt.scoreOn20))
              Center(
                child: Text(
                  AppStrings.t(context, 'passing_grade_reached'),
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ),
            if (_comeback != null) ...[
              const SizedBox(height: 20),
              _ComebackCard(
                plan: _comeback!,
                conceptName:
                    _conceptNames[_comeback!.conceptId] ?? _comeback!.conceptId,
                onStart: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ComebackPage(
                        contentRepository: widget.contentRepository,
                        plan: _comeback!,
                        conceptName: _conceptNames[_comeback!.conceptId] ??
                            _comeback!.conceptId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _percent(double accuracy) => (accuracy * 100).round();

  /// A 7-day comeback plan when this attempt failed and has a weak concept
  /// whose lesson can be looked up. Otherwise null.
  ComebackPlan? get _comeback {
    final attempt = widget.attempt;

    if (isPassingScore(attempt.scoreOn20)) {
      return null;
    }

    final weak = primaryWeakConcept(attempt);

    if (weak == null) {
      return null;
    }

    final lessonId = _lessonIds[weak.conceptId];

    if (lessonId == null || lessonId.isEmpty) {
      return null;
    }

    return buildComebackPlan(
      examId: attempt.examId,
      latestScore: attempt.scoreOn20,
      previousScore: _previousScore,
      weakConcept: weak,
      weakConceptLessonId: lessonId,
      languageCode: appLanguageOf(context),
    );
  }
}

class _ComebackCard extends StatelessWidget {
  final ComebackPlan plan;
  final String conceptName;
  final VoidCallback onStart;

  const _ComebackCard({
    required this.plan,
    required this.conceptName,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final improvement = plan.improvement;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepOrange.shade400,
            Colors.orange.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t(context, 'not_result_wanted_question'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.t(context, 'comeback_pitch', args: [conceptName]),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.92)),
          ),
          if (improvement != null) ...[
            const SizedBox(height: 10),
            Text(
              improvement >= 0
                  ? AppStrings.t(context, 'improving_vs',
                      args: [improvement.toStringAsFixed(1)])
                  : AppStrings.t(context, 'previous_attempt',
                      args: [plan.previousScore?.toStringAsFixed(1)]),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepOrange.shade600,
              ),
              onPressed: onStart,
              child: Text(
                AppStrings.t(context, 'start_comeback'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportGamification extends StatelessWidget {
  final GamificationResult result;

  const _ReportGamification({required this.result});

  @override
  Widget build(BuildContext context) {
    final levelUp = result.levelUp;
    final languageCode = appLanguageOf(context);

    if (levelUp == null && !result.hasNewAchievements) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (levelUp != null) ...[
              Text(
                AppStrings.t(context, 'level_up_banner'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.t(context, 'level_x_to_y',
                    args: [levelUp.oldLevel, levelUp.newLevel]),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            if (result.hasNewAchievements) ...[
              if (levelUp != null) const SizedBox(height: 12),
              for (final achievement in result.newAchievements)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(
                        achievement.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          achievement.titleForLanguage(languageCode),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        AppStrings.t(context, 'xp_reward',
                            args: [achievement.xpReward]),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConceptTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;
  final String detail;

  const _ConceptTile({
    required this.icon,
    required this.color,
    required this.name,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(detail),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }
}
