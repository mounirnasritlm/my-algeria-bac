import 'package:flutter/material.dart';

import '../config/app_language.dart';
import '../data/app_settings_repository.dart';
import '../data/student_profile_repository.dart';
import '../models/app_settings.dart';
import '../models/student_profile.dart';

/// Owns app-wide state that affects the shell, rather than a single feature.
class AppController extends ChangeNotifier {
  AppController({
    AppSettingsRepository? settingsRepository,
    StudentProfileRepository? profileRepository,
  })  : _settingsRepository = settingsRepository ?? AppSettingsRepository(),
        _profileRepository = profileRepository ?? StudentProfileRepository();

  final AppSettingsRepository _settingsRepository;
  final StudentProfileRepository _profileRepository;

  ThemePreference _themePreference = ThemePreference.system;
  StudentProfile? _studentProfile;
  String _languageCode = appLanguage;
  bool _initialized = false;
  bool _disposed = false;

  ThemePreference get themePreference => _themePreference;
  StudentProfile? get studentProfile => _studentProfile;
  String get languageCode => _languageCode;
  bool get initialized => _initialized;
  bool get needsOnboarding => _initialized && _studentProfile == null;

  ThemeMode get themeMode {
    switch (_themePreference) {
      case ThemePreference.system:
        return ThemeMode.system;
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
    }
  }

  Future<void> initialize() async {
    final preference = await _settingsRepository.loadThemePreference();
    final profile = await _profileRepository.load();
    if (_disposed) {
      return;
    }

    _themePreference = preference;
    _studentProfile = profile;
    _languageCode = normalizeAppLanguage(profile?.languageCode);
    _initialized = true;
    notifyListeners();
  }

  Future<void> setThemePreference(ThemePreference preference) async {
    if (_themePreference == preference) {
      return;
    }

    await _settingsRepository.saveThemePreference(preference);
    if (_disposed) {
      return;
    }

    _themePreference = preference;
    notifyListeners();
  }

  Future<void> saveStudentProfile(StudentProfile profile) async {
    await _profileRepository.save(profile);
    if (_disposed) {
      return;
    }

    _studentProfile = profile;
    _languageCode = normalizeAppLanguage(profile.languageCode);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
