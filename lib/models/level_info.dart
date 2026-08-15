/// 🏆 Level view for the UI: current level, current XP, and the thresholds
/// bounding it. `progress` and `remainingXp` are derived for progress bars.
class LevelInfo {
  final int level;
  final int currentXp;
  final int xpForCurrentLevel;
  final int xpForNextLevel;

  const LevelInfo({
    required this.level,
    required this.currentXp,
    required this.xpForCurrentLevel,
    required this.xpForNextLevel,
  });

  /// 0..1 progress through the current level (1 when maxed out).
  double get progress {
    final range = xpForNextLevel - xpForCurrentLevel;

    if (range <= 0) {
      return 1;
    }

    return ((currentXp - xpForCurrentLevel) / range).clamp(0.0, 1.0).toDouble();
  }

  int get remainingXp {
    final remaining = xpForNextLevel - currentXp;
    return remaining < 0 ? 0 : remaining;
  }
}

/// Emitted when a reward pushes the student into a new level, so the UI can
/// show the level-up moment instead of just a number changing.
class LevelUpEvent {
  final int oldLevel;
  final int newLevel;

  const LevelUpEvent({
    required this.oldLevel,
    required this.newLevel,
  });

  bool get leveledUp => newLevel > oldLevel;
}
