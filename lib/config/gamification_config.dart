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
}
