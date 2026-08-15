import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../data/study_plan_repository.dart';
import '../models/study_plan.dart';
import 'lesson_page.dart';
import 'study_settings_page.dart';

/// 🎯 Smart Study Plan: today's deterministic plan built from weak points,
/// unfinished lessons, and the student's available study minutes.
class StudyPlanPage extends StatefulWidget {
  final ContentRepository contentRepository;

  /// Injectable for tests; defaults to a repository over the real services.
  final StudyPlanRepository? planRepository;

  const StudyPlanPage({
    super.key,
    required this.contentRepository,
    this.planRepository,
  });

  @override
  State<StudyPlanPage> createState() => _StudyPlanPageState();
}

class _StudyPlanPageState extends State<StudyPlanPage> {
  late final StudyPlanRepository _repository;
  late Future<StudyPlan> _planFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.planRepository ??
        StudyPlanRepository(contentRepository: widget.contentRepository);
    _planFuture = _repository.generateTodayPlan();
  }

  Future<void> _refreshPlan() async {
    setState(() {
      _planFuture = _repository.generateTodayPlan();
    });

    await _planFuture;
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const StudySettingsPage(),
      ),
    );
  }

  void _openTask(StudyTask task) {
    final lessonId = task.lessonId;
    if (lessonId == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LessonPage(
          contentRepository: widget.contentRepository,
          lessonId: lessonId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Study Plan'),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.tune),
            tooltip: 'Study preferences',
          ),
        ],
      ),
      body: FutureBuilder<StudyPlan>(
        future: _planFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'We could not create your study plan.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _refreshPlan,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final plan = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refreshPlan,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                _PlanHeader(plan: plan),
                const SizedBox(height: 20),
                Text(
                  'Today',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 12),
                ...plan.tasks.map(
                  (task) => _StudyTaskCard(
                    task: task,
                    onOpen: () => _openTask(task),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlanHeader extends StatelessWidget {
  final StudyPlan plan;

  const _PlanHeader({required this.plan});

  @override
  Widget build(BuildContext context) {
    final completed = plan.completedTasks;
    final total = plan.tasks.length;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 SMART STUDY PLAN',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$completed / $total tasks',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${plan.availableMinutes} minutes available today',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: plan.completionRatio,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyTaskCard extends StatelessWidget {
  final StudyTask task;
  final VoidCallback onOpen;

  const _StudyTaskCard({
    required this.task,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              _TaskIcon(type: task.type),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          '${task.estimatedMinutes} min',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskIcon extends StatelessWidget {
  final StudyTaskType type;

  const _TaskIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      StudyTaskType.weakPoint => Icons.priority_high,
      StudyTaskType.lesson => Icons.menu_book,
      StudyTaskType.practice => Icons.bolt,
      StudyTaskType.review => Icons.replay,
      StudyTaskType.exam => Icons.assignment,
    };

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
