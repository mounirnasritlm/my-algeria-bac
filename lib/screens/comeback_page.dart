import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../models/comeback.dart';
import 'exam_session_page.dart';
import 'lesson_page.dart';
import 'quiz_page.dart';

/// The 7-day recovery plan shown after a failed exam attempt.
class ComebackPage extends StatefulWidget {
  final ContentRepository contentRepository;

  final ComebackPlan plan;

  final String conceptName;

  const ComebackPage({
    super.key,
    required this.contentRepository,
    required this.plan,
    required this.conceptName,
  });

  @override
  State<ComebackPage> createState() => _ComebackPageState();
}

class _ComebackPageState extends State<ComebackPage> {
  String get _formattedScore {
    final score = widget.plan.latestScore;
    return score == score.roundToDouble()
        ? score.toStringAsFixed(0)
        : score.toStringAsFixed(1);
  }

  void _launch(ComebackDay day) {
    final repo = widget.contentRepository;

    switch (day.kind) {
      case ComebackDayKind.review:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                LessonPage(contentRepository: repo, lessonId: widget.plan.lessonId),
          ),
        );
      case ComebackDayKind.practice:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                QuizPage(contentRepository: repo, lessonId: widget.plan.lessonId),
          ),
        );
      case ComebackDayKind.rematch:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ExamSessionPage(
              contentRepository: repo,
              examId: widget.plan.examId,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final improvement = plan.improvement;

    return Scaffold(
      appBar: AppBar(title: const Text('Comeback plan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
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
                    'Not the result you wanted.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Here is your 7-day plan to beat it.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'Last score',
                          value: '$_formattedScore/20',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniStat(
                          label: 'Target',
                          value: '10/20',
                        ),
                      ),
                      if (improvement != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniStat(
                            label: improvement >= 0 ? 'Up' : 'Down',
                            value:
                                '${improvement >= 0 ? '+' : ''}'
                                '${improvement.toStringAsFixed(1)}',
                            emphasized: improvement >= 0,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Main target: ${widget.conceptName}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Days 1–3 build this concept back up, day 4 is a timed '
              'rehearsal, and day 7 is the rematch.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            for (final day in plan.days)
              _DayCard(
                day: day,
                onLaunch: () => _launch(day),
              ),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: () => _launch(plan.days.last),
                icon: const Icon(Icons.sports_kabaddi),
                label: const Text(
                  'Rematch now',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _MiniStat({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: emphasized ? Colors.green.shade200 : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final ComebackDay day;

  final VoidCallback onLaunch;

  const _DayCard({required this.day, required this.onLaunch});

  IconData get _icon {
    switch (day.kind) {
      case ComebackDayKind.review:
        return Icons.menu_book_outlined;
      case ComebackDayKind.practice:
        return Icons.edit_outlined;
      case ComebackDayKind.rematch:
        return Icons.timer_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        title: Text(day.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(day.description),
        trailing: Icon(_icon, color: Theme.of(context).colorScheme.primary),
        onTap: onLaunch,
      ),
    );
  }
}
