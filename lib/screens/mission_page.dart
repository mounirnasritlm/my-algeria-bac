import 'package:flutter/material.dart';

import '../data/campaign_engine.dart';
import '../data/content_repository.dart';
import '../data/progress_repository.dart';
import '../models/bac_campaign.dart';
import '../models/exam.dart';
import 'exam_session_page.dart';
import 'weak_points_page.dart';

/// Mission du Jour: today's real mission, its progress, and the XP reward.
/// Every number comes from the attempt tables — nothing is decorative.
class MissionPage extends StatefulWidget {
  final ContentRepository contentRepository;

  /// Called to switch a bottom-navigation tab (generic practice missions).
  final ValueChanged<int>? onNavigateToTab;

  const MissionPage({
    super.key,
    required this.contentRepository,
    this.onNavigateToTab,
  });

  @override
  State<MissionPage> createState() => _MissionPageState();
}

class _MissionPageState extends State<MissionPage> {
  final ProgressRepository _progress = ProgressRepository();

  bool _loading = true;

  DailyMission? _mission;
  List<Exam> _exams = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = DateTime.now();

    final mastery = await _progress.getAllConceptMastery();
    final activity = await _progress.getDailyActivity(today);

    final mission = missionFor(
      today: today,
      mastery: mastery,
      activity: activity,
    );

    // Reward once per day, guarded by the completion date.
    await _progress.awardMissionXp(mission, today);

    final exams = await widget.contentRepository.getExams();

    if (!mounted) {
      return;
    }

    setState(() {
      _mission = mission;
      _exams = exams;
      _loading = false;
    });
  }

  void _launch() {
    final mission = _mission;
    if (mission == null) {
      return;
    }

    switch (mission.type) {
      case DailyMissionType.rescue:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WeakPointsPage(
              contentRepository: widget.contentRepository,
            ),
          ),
        );
      case DailyMissionType.bacExercise:
      case DailyMissionType.bacChallenge:
        if (_exams.isEmpty) {
          return;
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ExamSessionPage(
              contentRepository: widget.contentRepository,
              examId: _exams.first.id,
            ),
          ),
        );
      default:
        Navigator.of(context).pop();
        widget.onNavigateToTab?.call(1); // Learn tab
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mission du Jour')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _mission == null
              ? const Center(child: Text('No mission available.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _header(context),
                      const SizedBox(height: 20),
                      _progressCard(context, _mission!),
                      const SizedBox(height: 20),
                      _action(context, _mission!),
                    ],
                  ),
                ),
    );
  }

  Widget _header(BuildContext context) {
    final mission = _mission!;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _colors(mission.type),
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
              Icon(_icon(mission.type), color: Colors.white, size: 26),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'MISSION DU JOUR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'TODAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            mission.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mission.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressCard(BuildContext context, DailyMission mission) {
    final fraction = mission.target == 0
        ? 0.0
        : (mission.progress / mission.target).clamp(0.0, 1.0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Today's progress",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                ),
                Text(
                  '${mission.progress} / ${mission.target}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(value: fraction, minHeight: 10),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.bolt, color: Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Text(
                  '+${mission.rewardXp} XP',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                if (mission.isComplete)
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 6),
                      Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w800,
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

  Widget _action(BuildContext context, DailyMission mission) {
    if (mission.isComplete) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.green),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mission completed! XP awarded.',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Come back tomorrow for a new challenge.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _launch,
        child: Text(_buttonLabel(mission.type)),
      ),
    );
  }

  String _buttonLabel(DailyMissionType type) {
    switch (type) {
      case DailyMissionType.rescue:
        return 'Fix this weakness';
      case DailyMissionType.bacExercise:
      case DailyMissionType.bacChallenge:
        return 'Start the exam';
      default:
        return 'Start practice';
    }
  }

  IconData _icon(DailyMissionType type) {
    switch (type) {
      case DailyMissionType.rescue:
        return Icons.favorite_outline;
      case DailyMissionType.speed:
        return Icons.bolt;
      case DailyMissionType.memory:
        return Icons.psychology_outlined;
      case DailyMissionType.bacExercise:
        return Icons.fact_check_outlined;
      case DailyMissionType.precision:
        return Icons.gps_fixed;
      case DailyMissionType.bacChallenge:
        return Icons.sports_martial_arts;
      case DailyMissionType.foundation:
        return Icons.flag_outlined;
    }
  }

  List<Color> _colors(DailyMissionType type) {
    switch (type) {
      case DailyMissionType.rescue:
        return const [Color(0xFFF97316), Color(0xFFEA580C)];
      case DailyMissionType.speed:
        return const [Color(0xFFF59E0B), Color(0xFFD97706)];
      case DailyMissionType.memory:
        return const [Color(0xFF8B5CF6), Color(0xFF6D28D9)];
      case DailyMissionType.bacExercise:
        return const [Color(0xFF3B82F6), Color(0xFF2563EB)];
      case DailyMissionType.precision:
        return const [Color(0xFF14B8A6), Color(0xFF0F766E)];
      case DailyMissionType.bacChallenge:
        return const [Color(0xFF6366F1), Color(0xFF4F46E5)];
      case DailyMissionType.foundation:
        return const [Color(0xFF22C55E), Color(0xFF15803D)];
    }
  }
}
