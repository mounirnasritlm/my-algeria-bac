import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../config/feature_flags.dart';
import '../dev/developer_menu.dart';
import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../models/student_profile.dart';
import 'study_settings_page.dart';
import 'student_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.appController});

  final AppController? appController;

  @override
  Widget build(BuildContext context) {
    final profile = appController?.studentProfile;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t(context, 'profile_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.school_outlined,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                profile == null
                    ? AppStrings.t(context, 'profile_header_default_title')
                    : 'BAC ${profile.bacYear}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                profile == null
                    ? AppStrings.t(context, 'profile_header_default_subtitle')
                    : '${_streamLabel(context, profile.stream)} · '
                        '${profile.targetAverage.toStringAsFixed(1)} / 20',
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.t(context, 'settings_title'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                if (appController != null)
                  ListTile(
                    leading: const Icon(Icons.brightness_6_outlined),
                    title: Text(AppStrings.t(context, 'appearance')),
                    subtitle: Text(_themeLabel(context, appController!.themePreference)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _chooseTheme(context, appController!),
                  ),
                if (FeatureFlags.studyPreferences)
                  ListTile(
                    leading: const Icon(Icons.tune_outlined),
                    title: Text(AppStrings.t(context, 'study_preferences')),
                    subtitle:
                        Text(AppStrings.t(context, 'study_preferences_subtitle')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const StudySettingsPage(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.t(context, 'coming_next'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(
                profile == null
                    ? AppStrings.t(context, 'set_up_bac_profile')
                    : AppStrings.t(context, 'bac_profile'),
              ),
              subtitle: Text(
                profile == null
                    ? AppStrings.t(context, 'set_up_bac_profile_subtitle')
                    : '${AppStrings.t(context, 'minutes_per_day', args: [profile.dailyGoalMinutes])} · '
                        '${_languageLabel(profile.languageCode)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: appController == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => StudentProfilePage(
                            controller: appController!,
                            editing: profile != null,
                          ),
                        ),
                      );
                    },
            ),
          ),
          if (FeatureFlags.developerTools) ...[
            const SizedBox(height: 24),
            Text(
              'Developer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.developer_mode_outlined),
                title: const Text('Developer tools'),
                subtitle: const Text('Runtime state and diagnostics.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showDeveloperMenu(context, appController),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _chooseTheme(
    BuildContext context,
    AppController controller,
  ) async {
    final preference = await showDialog<ThemePreference>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.t(context, 'appearance')),
          content: RadioGroup<ThemePreference>(
            groupValue: controller.themePreference,
            onChanged: (value) => Navigator.of(context).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemePreference>(
                  value: ThemePreference.system,
                  title: Text(AppStrings.t(context, 'system_default')),
                ),
                RadioListTile<ThemePreference>(
                  value: ThemePreference.light,
                  title: Text(AppStrings.t(context, 'light')),
                ),
                RadioListTile<ThemePreference>(
                  value: ThemePreference.dark,
                  title: Text(AppStrings.t(context, 'dark')),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (preference != null) {
      await controller.setThemePreference(preference);
    }
  }

  String _themeLabel(BuildContext context, ThemePreference preference) {
    final key = switch (preference) {
      ThemePreference.system => 'system_default',
      ThemePreference.light => 'light',
      ThemePreference.dark => 'dark',
    };
    return AppStrings.t(context, key);
  }

  String _streamLabel(BuildContext context, BacStream stream) {
    final key = switch (stream) {
      BacStream.experimentalSciences => 'stream_experimental_sciences',
      BacStream.mathematics => 'stream_mathematics',
      BacStream.technicalMathematics => 'stream_technical_mathematics',
      BacStream.managementEconomics => 'stream_management_economics',
      BacStream.literaturePhilosophy => 'stream_literature_philosophy',
      BacStream.foreignLanguages => 'stream_foreign_languages',
      BacStream.arts => 'stream_arts',
    };
    return AppStrings.t(context, key);
  }

  String _languageLabel(String code) {
    switch (code) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      case 'fr':
      default:
        return 'Français';
    }
  }
}
