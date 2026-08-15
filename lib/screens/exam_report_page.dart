import 'package:flutter/material.dart';

import '../data/comeback_engine.dart';
import '../data/content_repository.dart';
import '../data/exam_scoring.dart';
import '../data/progress_repository.dart';
import '../models/comeback.dart';
import '../models/exam_attempt.dart';
import 'comeback_page.dart';
import 'exam_session_page.dart';

/// Report for a submitted exam: score /20, time management, and strong/weak
/// concepts from this attempt.
class ExamReportPage extends StatefulWidget {
  final ContentRepository contentRepository;

  final ExamAttempt attempt;

  final bool autoSubmitted;

  const ExamReportPage({
    super.key,
    required this.contentRepository,
    required this.attempt,
    required this.autoSubmitted,
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
        title: const Text('Exam report'),
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
                  'Time ran out — your exam was submitted automatically.',
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
                    'out of 20',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${attempt.correctCount}/${attempt.totalQuestions} '
                    'correct',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Time used',
                    value: _formattedTime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Time management',
                    value: timeManagementLabel(
                      timeUsedSeconds: attempt.timeUsedSeconds,
                      durationMinutes: attempt.durationMinutes,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Scores are a demo estimate: every question counts equally '
              'toward /20. Official point allocations are not part of the '
              'source content.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 24),
            Text(
              'Strong concepts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            if (attempt.conceptResults.where((c) => c.isStrength).isEmpty)
              _EmptyHint(text: 'Nothing to highlight yet.'),
            for (final concept
                in attempt.conceptResults.where((c) => c.isStrength))
              _ConceptTile(
                icon: Icons.check_circle_outline,
                color: Colors.green,
                name: _conceptNames[concept.conceptId] ?? concept.conceptId,
                detail: '${_percent(concept.accuracy)}% correct',
              ),
            const SizedBox(height: 24),
            Text(
              'Weak concepts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            if (attempt.conceptResults.where((c) => c.isWeakness).isEmpty)
              _EmptyHint(text: 'No weak concepts in this attempt.'),
            for (final concept
                in attempt.conceptResults.where((c) => c.isWeakness))
              _ConceptTile(
                icon: Icons.error_outline,
                color: Colors.orange,
                name: _conceptNames[concept.conceptId] ?? concept.conceptId,
                detail: '${_percent(concept.accuracy)}% correct',
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
                      child: const Text(
                        'Rematch',
                        style: TextStyle(fontWeight: FontWeight.w700),
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
                      child: const Text('Back to practice'),
                    ),
                  ),
                ],
              ),
            ),
            if (isPassingScore(attempt.scoreOn20)) const SizedBox(height: 12),
            if (isPassingScore(attempt.scoreOn20))
              Center(
                child: Text(
                  'Passing grade reached — keep it up!',
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
          const Text(
            'Not the result you wanted?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'We built a 7-day plan around $conceptName to get you back '
            'on track.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.92)),
          ),
          if (improvement != null) ...[
            const SizedBox(height: 10),
            Text(
              improvement >= 0
                  ? 'You are improving: +'
                      '${improvement.toStringAsFixed(1)} vs your previous '
                      'attempt.'
                  : 'Previous attempt: ${plan.previousScore?.toStringAsFixed(1)}'
                      '/20. This is where the rematch starts.',
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
              child: const Text(
                'Start comeback',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
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
