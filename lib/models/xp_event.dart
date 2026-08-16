/// Where XP came from. Lives in the model layer so both config and services
/// can reference it without importing each other.
enum XpSource {
  lesson,
  quiz,
  practice,
  bacBoss,
  exam,
  dailyMission,
  achievement,
}
