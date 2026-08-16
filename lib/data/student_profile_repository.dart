import 'package:shared_preferences/shared_preferences.dart';

import '../models/student_profile.dart';

/// Persists the student profile independently from progress and content data.
class StudentProfileRepository {
  static const String streamKey = 'student_profile_stream';
  static const String bacYearKey = 'student_profile_bac_year';
  static const String targetAverageKey = 'student_profile_target_average';
  static const String languageKey = 'student_profile_language';
  static const String dailyGoalMinutesKey = 'student_profile_daily_goal';

  Future<StudentProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stream = prefs.getString(streamKey);
    final bacYear = prefs.getInt(bacYearKey);
    final targetAverage = prefs.getDouble(targetAverageKey);
    final languageCode = prefs.getString(languageKey);
    final dailyGoalMinutes = prefs.getInt(dailyGoalMinutesKey);

    if (stream == null ||
        bacYear == null ||
        targetAverage == null ||
        languageCode == null ||
        dailyGoalMinutes == null) {
      return null;
    }

    return StudentProfile(
      stream: bacStreamFromStorage(stream),
      bacYear: bacYear,
      targetAverage: targetAverage,
      languageCode: languageCode,
      dailyGoalMinutes: dailyGoalMinutes,
    );
  }

  Future<void> save(StudentProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(streamKey, profile.stream.storageValue);
    await prefs.setInt(bacYearKey, profile.bacYear);
    await prefs.setDouble(targetAverageKey, profile.targetAverage);
    await prefs.setString(languageKey, profile.languageCode);
    await prefs.setInt(dailyGoalMinutesKey, profile.dailyGoalMinutes);
  }
}
