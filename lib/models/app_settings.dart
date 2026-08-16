/// Theme choices that can be persisted independently from learning data.
enum ThemePreference {
  system,
  light,
  dark,
}

extension ThemePreferenceStorage on ThemePreference {
  String get storageValue {
    switch (this) {
      case ThemePreference.system:
        return 'system';
      case ThemePreference.light:
        return 'light';
      case ThemePreference.dark:
        return 'dark';
    }
  }
}

ThemePreference themePreferenceFromStorage(String? value) {
  switch (value) {
    case 'light':
      return ThemePreference.light;
    case 'dark':
      return ThemePreference.dark;
    case 'system':
    default:
      return ThemePreference.system;
  }
}
