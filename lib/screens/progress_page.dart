import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../data/progress_repository.dart';
import '../models/user_progress.dart';
import 'weak_points_page.dart';

class ProgressPage extends StatefulWidget {
  final ContentRepository contentRepository;

  const ProgressPage({
    super.key,
    required this.contentRepository,
  });

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final ProgressRepository repository = ProgressRepository();

  bool loading = true;

  int totalXp = 0;
  int currentStreak = 0;
  int longestStreak = 0;

  double accuracy = 0;

  List<LessonProgress> lessonProgress = [];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final results = await Future.wait([
      repository.getTotalXp(),
      repository.getCurrentStreak(),
      repository.getLongestStreak(),
      repository.getOverallAccuracy(),
      repository.getAllLessonProgress(),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      totalXp = results[0] as int;
      currentStreak = results[1] as int;
      longestStreak = results[2] as int;
      accuracy = results[3] as double;
      lessonProgress = results[4] as List<LessonProgress>;
      loading = false;
    });
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

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadProgress,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Progress',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),

            const SizedBox(height: 6),

            Text(
              'Your learning history',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.bolt,
                    value: '$totalXp',
                    label: 'XP',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department,
                    value: '$currentStreak',
                    label: 'Day streak',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.percent,
                    value: '${(accuracy * 100).round()}%',
                    label: 'Accuracy',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.emoji_events_outlined,
                    value: '$longestStreak',
                    label: 'Best streak',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(18),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.priority_high,
                    color: Colors.red,
                  ),
                ),
                title: const Text(
                  'My weak points',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: const Text(
                  'Find what needs the most revision.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WeakPointsPage(
                        contentRepository: widget.contentRepository,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Lesson progress',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),

            const SizedBox(height: 12),

            if (lessonProgress.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 48,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No completed lessons yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Complete a quiz and your progress will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            for (final progress in lessonProgress)
              _LessonProgressCard(
                progress: progress,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonProgressCard extends StatelessWidget {
  final LessonProgress progress;

  const _LessonProgressCard({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = (progress.accuracy * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    progress.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${progress.xpEarned} XP',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.accuracy,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.questionsCorrect}/${progress.questionsAnswered} correct',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '$accuracy%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
