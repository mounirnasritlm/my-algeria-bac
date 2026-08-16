import '../models/xp_event.dart';

/// Single authoritative location for gamification rules (streaks, XP, daily
/// goals). Values here are product decisions — feature code should never
/// hardcode these numbers inline.
class GamificationConfig {
  const GamificationConfig._();

  /// Real study minutes required before a calendar day counts toward the
  /// streak. Guards against "answer one question = streak day" farming.
  static const int minimumDailyMinutes = 10;

  /// Daily XP target shown to the student (informational goal).
  static const int dailyXpGoal = 50;

  static const int streakFreezeCost = 100;

  static const int streakFreezeLimit = 1;

  /// Cumulative XP required to reach each level above 1. Level is purely
  /// derived from total XP (see `data/levels_engine.dart`); nothing stores it.
  static const List<int> levelThresholds = [
    100,
    250,
    500,
    850,
    1300,
    1850,
    2500,
    3250,
    4100,
    5000,
  ];

  /// The XP value of one unit of each activity type.
  static int xpForSource(XpSource source) {
    switch (source) {
      case XpSource.lesson:
        return 10;
      case XpSource.quiz:
        return 15;
      case XpSource.practice:
        return 15;
      case XpSource.bacBoss:
        return 30;
      case XpSource.exam:
        return 40;
      case XpSource.dailyMission:
        return 25;
      case XpSource.achievement:
        return 50;
    }
  }
}
