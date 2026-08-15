/// 🏆 XP → Level progression. Pure logic, no I/O.
///
/// Levels are always DERIVED from the student's total XP (the sum of the
/// `xp_events` ledger plus per-lesson XP). Nothing stores the level, so the
/// level can never drift from the XP that earned it.
library;

import '../config/gamification_config.dart';
import '../models/level_info.dart';

/// Level for a given total XP using the authoritative threshold table.
///
/// Level 1 is the starting level. Every threshold crossed adds one level.
int levelFor(int totalXp) {
  var level = 1;

  for (final threshold in GamificationConfig.levelThresholds) {
    if (totalXp >= threshold) {
      level++;
    } else {
      break;
    }
  }

  return level;
}

/// The XP at which [level] started (0 for level 1).
int levelFloor(int level) {
  if (level <= 1) {
    return 0;
  }

  final index = level - 2;
  final thresholds = GamificationConfig.levelThresholds;

  if (index >= thresholds.length) {
    return thresholds.last;
  }

  return thresholds[index];
}

/// The XP at which [level] levels up to the next level. At max level the
/// floor is returned so the progress bar is full.
int nextLevelFloor(int level) {
  final thresholds = GamificationConfig.levelThresholds;
  final index = level - 1;

  if (index >= thresholds.length) {
    return levelFloor(level);
  }

  return thresholds[index];
}

/// Full level view for a given total XP.
LevelInfo levelInfoFor(int totalXp) {
  final level = levelFor(totalXp);

  return LevelInfo(
    level: level,
    currentXp: totalXp,
    xpForCurrentLevel: levelFloor(level),
    xpForNextLevel: nextLevelFloor(level),
  );
}
