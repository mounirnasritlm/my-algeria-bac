import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../data/progress_repository.dart';
import '../l10n/app_strings.dart';
import '../models/weak_point.dart';
import 'lesson_page.dart';

/// Weak Point Hunter: the evidence-backed list of concepts that need work.
///
/// Nothing here is guessed. A concept only appears once it has enough
/// attempts (>= 3), and it is ranked by recency-weighted mastery, so one
/// fluke answer never brands a concept as weak.
class WeakPointsPage extends StatefulWidget {
  final ContentRepository contentRepository;

  /// Injectable for tests; defaults to the real repository.
  final ProgressRepository? progressRepository;

  const WeakPointsPage({
    super.key,
    required this.contentRepository,
    this.progressRepository,
  });

  @override
  State<WeakPointsPage> createState() => _WeakPointsPageState();
}

class _WeakPointsPageState extends State<WeakPointsPage> {
  late final ProgressRepository progressRepository;

  bool loading = true;

  List<_WeakPoint> weakPoints = [];

  @override
  void initState() {
    super.initState();
    progressRepository = widget.progressRepository ?? ProgressRepository();
    _load();
  }

  Future<void> _load() async {
    final found = await progressRepository.getWeakPoints();

    final result = <_WeakPoint>[];

    for (final weakPoint in found) {
      final concept =
          await widget.contentRepository.getConcept(weakPoint.conceptId);

      result.add(
        _WeakPoint(
          weakPoint: weakPoint,
          title: concept?.name ?? weakPoint.conceptId,
        ),
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      weakPoints = result;
      loading = false;
    });
  }

  void _train(_WeakPoint weakPoint) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LessonPage(
          contentRepository: widget.contentRepository,
          lessonId: weakPoint.weakPoint.lessonId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t(context, 'weak_point_hunter')),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : weakPoints.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _HunterHeader(count: weakPoints.length),
                      const SizedBox(height: 16),
                      ...weakPoints.map(
                        (weakPoint) => _WeakPointCard(
                          weakPoint: weakPoint,
                          onTrain: () => _train(weakPoint),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _WeakPoint {
  final WeakPoint weakPoint;
  final String title;

  const _WeakPoint({required this.weakPoint, required this.title});
}

class _HunterHeader extends StatelessWidget {
  final int count;

  const _HunterHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gps_fixed, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                AppStrings.t(context, 'weak_point_hunter_badge'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            count == 1
                ? AppStrings.t(context, 'weak_points_header_one')
                : AppStrings.t(context, 'weak_points_header_many',
                    args: [count]),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.t(context, 'weak_points_evidence'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeakPointCard extends StatelessWidget {
  final _WeakPoint weakPoint;
  final VoidCallback onTrain;

  const _WeakPointCard({required this.weakPoint, required this.onTrain});

  @override
  Widget build(BuildContext context) {
    final mastery = weakPoint.weakPoint.mastery;
    final percentage = (mastery * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    weakPoint.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _PriorityBadge(priority: weakPoint.weakPoint.priority),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(value: mastery),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  AppStrings.t(context, 'percent_mastery',
                      args: [percentage]),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  AppStrings.t(context, 'attempts_count',
                      args: [weakPoint.weakPoint.attempts]),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onTrain,
                child: Text(AppStrings.t(context, 'train_this_weakness')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final WeakPointPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      WeakPointPriority.critical => const Color(0xFFDC2626),
      WeakPointPriority.high => const Color(0xFFF97316),
      WeakPointPriority.medium => const Color(0xFFF59E0B),
      WeakPointPriority.low => const Color(0xFF22C55E),
    };

    final label = switch (priority) {
      WeakPointPriority.critical => AppStrings.t(context, 'priority_critical'),
      WeakPointPriority.high => AppStrings.t(context, 'priority_high'),
      WeakPointPriority.medium => AppStrings.t(context, 'priority_medium'),
      WeakPointPriority.low => AppStrings.t(context, 'priority_low'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(
              AppStrings.t(context, 'not_enough_data'),
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.t(context, 'not_enough_data_hint'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
