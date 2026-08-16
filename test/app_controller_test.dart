import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_algeria_bac/app/app_controller.dart';
import 'package:my_algeria_bac/data/app_settings_repository.dart';
import 'package:my_algeria_bac/models/app_settings.dart';

void main() {
  test('defaults to the system theme when no preference is stored', () async {
    SharedPreferences.setMockInitialValues({});

    final controller = AppController();
    await controller.initialize();

    expect(controller.themePreference, ThemePreference.system);
    expect(controller.themeMode, ThemeMode.system);
    controller.dispose();
  });

  test('loads and persists the selected theme', () async {
    SharedPreferences.setMockInitialValues({
      AppSettingsRepository.themePreferenceKey: 'dark',
    });

    final controller = AppController();
    await controller.initialize();
    expect(controller.themeMode, ThemeMode.dark);

    await controller.setThemePreference(ThemePreference.light);
    expect(controller.themeMode, ThemeMode.light);

    final reloaded = AppController();
    await reloaded.initialize();
    expect(reloaded.themePreference, ThemePreference.light);

    controller.dispose();
    reloaded.dispose();
  });
}
