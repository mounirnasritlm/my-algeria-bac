import 'package:flutter/material.dart';

import '../config/gamification_config.dart';
import '../data/streak_repository.dart';
import '../l10n/app_strings.dart';
import '../models/streak.dart';

/// 🔥 BAC Streak 2.0: earned by real, completed learning activity, not by
/// opening the app. Everything shown here is derived from the recorded
/// streak activities.
class StreakPage extends StatefulWidget {
  /// Injectable for tests; defaults to the real repository.
  final StreakRepository? repository;

  const StreakPage({
    super.key,
    this.repository,
  });

  @override
  State<StreakPage> createState() => _StreakPageState();
}

class _StreakPageState extends State<StreakPage> {
  late final StreakRepository _repository =
      widget.repository ?? StreakRepository();
  late Future<StreakState> _stateFuture;

  @override
  void initState() {
    super.initState();
    _stateFuture = _repository.getState();
  }

  Future<void> _refresh() async {
    setState(() {
      _stateFuture = _repository.getState();
    });

    await _stateFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t(context, 'my_streak'))),
      body: FutureBuilder<StreakState>(
        future: _stateFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(AppStrings.t(context, 'unable_to_load_streak')),
            );
          }

          final state = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                _HeroStreak(state: state),
                const SizedBox(height: 20),
                _TodayCard(state: state),
                const SizedBox(height: 20),
                _MilestoneCard(streak: state.currentStreak),
                const SizedBox(height: 20),
                const _MotivationCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroStreak extends StatelessWidget {
  final StreakState state;

  const _HeroStreak({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF7C2D12), Color(0xFFEA580C)],
        ),
      ),
      child: Column(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 62)),
          const SizedBox(height: 8),
          Text(
            '${state.currentStreak}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            AppStrings.t(context, 'day_streak'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.t(context, 'longest_days',
                args: [state.longestStreak]),
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final StreakState state;

  const _TodayCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final goal = GamificationConfig.minimumDailyMinutes;
    final progress = (state.todayMinutes / goal).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t(context, 'today'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(value: progress, minHeight: 10),
            const SizedBox(height: 10),
            Text(
              AppStrings.t(context, 'minutes_of_goal',
                  args: [state.todayMinutes, goal]),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              state.completedToday
                  ? AppStrings.t(context, 'streak_alive_today')
                  : AppStrings.t(context, 'streak_goal_hint', args: [goal]),
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final int streak;

  const _MilestoneCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final next = _nextMilestone(streak);

    return Card(
      child: ListTile(
        leading: const Text('🏆', style: TextStyle(fontSize: 30)),
        title: Text(
          AppStrings.t(context, 'next_milestone'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          AppStrings.t(context, 'milestone_days', args: [next]),
        ),
      ),
    );
  }

  int _nextMilestone(int streak) {
    const milestones = [3, 7, 14, 30, 50, 100, 180, 365];

    for (final milestone in milestones) {
      if (streak < milestone) {
        return milestone;
      }
    }

    return 365;
  }
}

class _MotivationCard extends StatelessWidget {
  const _MotivationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: const Column(
        children: [
          Text('🇩🇿', style: TextStyle(fontSize: 38)),
          SizedBox(height: 8),
          Text(
            'Chaque jour compte.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'ماشي لازم تقرا بزاف كل يوم. '
            'المهم ما توقفش.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.4),
          ),
        ],
      ),
    );
  }
}
