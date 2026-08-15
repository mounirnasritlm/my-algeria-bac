import 'package:shared_preferences/shared_preferences.dart';

import '../models/study_preferences.dart';

/// Persists study preferences in shared_preferences. These are simple
/// key-value settings (minutes, toggles, subject ids); structured learning
/// data never lives here.
class StudyPreferencesRepository {
  static const String _dailyMinutesKey = 'study_daily_minutes';
  static const String _subjectsKey = 'study_preferred_subjects';
  static const String _weakPointsKey = 'study_include_weak_points';
  static const String _lessonsKey = 'study_include_lessons';
  static const String _practiceKey = 'study_include_practice';

  Future<StudyPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();

    return StudyPreferences(
      dailyMinutes: prefs.getInt(_dailyMinutesKey) ?? 45,
      preferredSubjectIds:
          prefs.getStringList(_subjectsKey) ?? const [],
      includeWeakPoints: prefs.getBool(_weakPointsKey) ?? true,
      includeLessons: prefs.getBool(_lessonsKey) ?? true,
      includePractice: prefs.getBool(_practiceKey) ?? true,
    );
  }

  Future<void> save(StudyPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_dailyMinutesKey, preferences.dailyMinutes);
    await prefs.setStringList(_subjectsKey, preferences.preferredSubjectIds);
    await prefs.setBool(_weakPointsKey, preferences.includeWeakPoints);
    await prefs.setBool(_lessonsKey, preferences.includeLessons);
    await prefs.setBool(_practiceKey, preferences.includePractice);
  }
}
