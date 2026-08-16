import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

/// Persists app-wide preferences such as appearance without mixing them into
/// structured learning data.
class AppSettingsRepository {
  static const String themePreferenceKey = 'app_theme_preference';

  Future<ThemePreference> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return themePreferenceFromStorage(prefs.getString(themePreferenceKey));
  }

  Future<void> saveThemePreference(ThemePreference preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themePreferenceKey, preference.storageValue);
  }
}
