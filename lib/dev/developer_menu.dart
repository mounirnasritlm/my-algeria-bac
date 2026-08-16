import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_controller.dart';
import '../config/achievements.dart';
import '../config/feature_flags.dart';
import '../content/content_coordinator.dart';
import '../data/achievement_repository.dart';
import '../data/app_database.dart';
import '../data/progress_repository.dart';
import '../data/streak_repository.dart';
import '../models/streak.dart';

/// Debug-only panel that surfaces runtime state and offers destructive/dev
/// shortcuts for exercising the app without replaying real study flows.
///
/// Reachable only when [FeatureFlags.developerTools] is enabled, so it is
/// compiled into release builds but never surfaced to users. Text is
/// intentionally English: this is a developer tool, not product UI.
Future<void> showDeveloperMenu(
  BuildContext context,
  AppController? controller,
  ContentCoordinator? coordinator,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DeveloperMenu(controller: controller, coordinator: coordinator),
  );
}

class DeveloperMenu extends StatefulWidget {
  const DeveloperMenu({super.key, this.controller, this.coordinator});

  final AppController? controller;

  final ContentCoordinator? coordinator;

  @override
  State<DeveloperMenu> createState() => _DeveloperMenuState();
}

class _DeveloperMenuState extends State<DeveloperMenu> {
  bool _busy = false;

  static const _flags = <String, bool>{
    'remoteContentSync': FeatureFlags.remoteContentSync,
    'studyPreferences': FeatureFlags.studyPreferences,
    'developerTools': FeatureFlags.developerTools,
    'onboarding': FeatureFlags.onboarding,
  };

  String _diagnostics() {
    final flags = _flags.entries
        .map((e) => '${e.key}=${e.value}')
        .join(', ');
    final buffer = StringBuffer()
      ..writeln('Language: ${widget.controller?.languageCode ?? '—'}')
      ..writeln('Theme: ${widget.controller?.themePreference.name ?? '—'}')
      ..writeln('Profile saved: ${widget.controller?.studentProfile != null}')
      ..writeln('Onboarding needed: ${widget.controller?.needsOnboarding ?? false}')
      ..writeln('DB schema version: ${ProgressDatabase.databaseVersion}')
      ..write('Flags: $flags');
    return buffer.toString();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _forceContentSync() async {
    final coordinator = widget.coordinator;
    if (coordinator == null) {
      return;
    }
    await _run(() async {
      final result = await coordinator.syncNow();
      _showSnack('Sync finished: ${result.status.name}');
    });
  }

  Future<void> _reloadContent() async {
    final coordinator = widget.coordinator;
    if (coordinator == null) {
      return;
    }
    await _run(() async {
      await coordinator.initialize();
      _showSnack('Content reloaded.');
    });
  }

  Future<void> _clearContentCache() async {
    final coordinator = widget.coordinator;
    if (coordinator == null) {
      return;
    }
    await _run(() async {
      await coordinator.manager.clearCache();
      await coordinator.initialize();
      _showSnack('Content cache cleared.');
    });
  }

  Future<void> _grantXp() async {
    await _run(() async {
      await ProgressRepository().addXp(reason: 'developer_tools', amount: 100);
      _showSnack('Granted 100 XP.');
    });
  }

  Future<void> _setStreak() async {
    await _run(() async {
      await StreakRepository().recordActivity(
        activityId: 'dev_tools_streak',
        type: StreakActivityType.studySession,
        xpEarned: 0,
        minutes: 30,
      );
      _showSnack('Recorded a study activity for today.');
    });
  }

  Future<void> _unlockAchievement() async {
    await _run(() async {
      await AchievementRepository().unlock(Achievements.firstLesson);
      _showSnack('Unlocked "First Step".');
    });
  }

  Future<void> _completeFirstLesson() async {
    final coordinator = widget.coordinator;
    if (coordinator == null) {
      _showSnack('Content coordinator is unavailable.');
      return;
    }
    await _run(() async {
      final repository = coordinator.repository;
      final subjects = await repository.getSubjects();
      if (subjects.isEmpty) {
        _showSnack('No subjects available.');
        return;
      }
      final chapters = await repository.getChaptersForSubject(subjects.first.id);
      if (chapters.isEmpty) {
        _showSnack('No chapters available.');
        return;
      }
      final lessons = await repository.getLessonsForChapter(chapters.first.id);
      if (lessons.isEmpty) {
        _showSnack('No lessons available.');
        return;
      }
      final lesson = lessons.first;
      await ProgressRepository().saveLessonResult(
        lessonId: lesson.id,
        lessonTitle: lesson.titleForLanguage('en'),
        questionsAnswered: 5,
        questionsCorrect: 5,
        xpEarned: 50,
      );
      _showSnack('Completed "${lesson.titleForLanguage('en')}".');
    });
  }

  Future<void> _resetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset all progress?'),
          content: const Text(
            'Deletes lessons, attempts, XP, streaks, and achievements. '
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    await _run(() async {
      await ProgressDatabase.instance.resetUserData();
      _showSnack('Progress reset.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = widget.coordinator != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Developer tools',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 16),
            _sectionTitle(context, 'Runtime'),
            _row(context, 'Language', widget.controller?.languageCode ?? '—'),
            _row(
              context,
              'Theme',
              widget.controller?.themePreference.name ?? '—',
            ),
            _row(
              context,
              'Profile saved',
              '${widget.controller?.studentProfile != null}',
            ),
            _row(
              context,
              'Onboarding needed',
              '${widget.controller?.needsOnboarding ?? false}',
            ),
            const SizedBox(height: 12),
            _sectionTitle(context, 'Storage'),
            _row(context, 'DB schema version', '${ProgressDatabase.databaseVersion}'),
            const SizedBox(height: 12),
            _sectionTitle(context, 'Feature flags'),
            for (final entry in _flags.entries)
              _row(context, entry.key, '${entry.value}'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: _diagnostics()));
                      _showSnack('Diagnostics copied.');
                    },
              icon: const Icon(Icons.copy),
              label: const Text('Copy diagnostics'),
            ),
            const SizedBox(height: 20),
            _sectionTitle(context, 'Content actions'),
            _actionButton(
              context,
              Icons.sync,
              'Force content sync',
              hasContent ? _forceContentSync : null,
            ),
            _actionButton(
              context,
              Icons.refresh,
              'Reload content',
              hasContent ? _reloadContent : null,
            ),
            _actionButton(
              context,
              Icons.delete_sweep_outlined,
              'Clear content cache',
              hasContent ? _clearContentCache : null,
            ),
            const SizedBox(height: 12),
            _sectionTitle(context, 'Progress shortcuts'),
            _actionButton(
              context,
              Icons.bolt,
              'Grant 100 XP',
              _grantXp,
            ),
            _actionButton(
              context,
              Icons.local_fire_department,
              'Record today’s streak activity',
              _setStreak,
            ),
            _actionButton(
              context,
              Icons.emoji_events_outlined,
              'Unlock "First Step"',
              _unlockAchievement,
            ),
            _actionButton(
              context,
              Icons.school_outlined,
              'Complete first lesson',
              _completeFirstLesson,
            ),
            const SizedBox(height: 12),
            _sectionTitle(context, 'Danger zone'),
            _actionButton(
              context,
              Icons.delete_forever_outlined,
              'Reset progress',
              _resetProgress,
              danger: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    IconData icon,
    String label,
    Future<void> Function()? onPressed, {
    bool danger = false,
  }) {
    final color = danger ? Theme.of(context).colorScheme.error : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilledButton.tonalIcon(
        onPressed: _busy || onPressed == null ? null : onPressed,
        icon: Icon(icon, color: color),
        style: danger
            ? FilledButton.styleFrom(foregroundColor: color)
            : null,
        label: Text(label),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
