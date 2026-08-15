/// Student-configurable study preferences. These are small key-value settings
/// (kept in shared_preferences), separate from structured learning data that
/// stays in SQLite.
class StudyPreferences {
  final int dailyMinutes;
  final List<String> preferredSubjectIds;
  final bool includeWeakPoints;
  final bool includeLessons;
  final bool includePractice;

  const StudyPreferences({
    required this.dailyMinutes,
    required this.preferredSubjectIds,
    required this.includeWeakPoints,
    required this.includeLessons,
    required this.includePractice,
  });

  const StudyPreferences.defaults()
      : dailyMinutes = 45,
        preferredSubjectIds = const [],
        includeWeakPoints = true,
        includeLessons = true,
        includePractice = true;
}
