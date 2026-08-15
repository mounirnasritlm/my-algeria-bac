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
}
