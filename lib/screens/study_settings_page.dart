import 'package:flutter/material.dart';

import '../data/study_preferences_repository.dart';
import '../l10n/app_strings.dart';
import '../models/study_preferences.dart';

/// Let the student choose how much time they have and what the plan should
/// include. Nothing here touches learning data — it is plain preferences.
class StudySettingsPage extends StatefulWidget {
  /// Injectable for tests; defaults to the real repository.
  final StudyPreferencesRepository? repository;

  const StudySettingsPage({super.key, this.repository});

  @override
  State<StudySettingsPage> createState() => _StudySettingsPageState();
}

class _StudySettingsPageState extends State<StudySettingsPage> {
  late final StudyPreferencesRepository _repository;

  int dailyMinutes = 45;
  bool weakPoints = true;
  bool lessons = true;
  bool practice = true;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? StudyPreferencesRepository();
    _load();
  }

  Future<void> _load() async {
    final preferences = await _repository.load();

    if (!mounted) {
      return;
    }

    setState(() {
      dailyMinutes = preferences.dailyMinutes;
      weakPoints = preferences.includeWeakPoints;
      lessons = preferences.includeLessons;
      practice = preferences.includePractice;
      loading = false;
    });
  }

  Future<void> _save() async {
    await _repository.save(
      StudyPreferences(
        dailyMinutes: dailyMinutes,
        preferredSubjectIds: const [],
        includeWeakPoints: weakPoints,
        includeLessons: lessons,
        includePractice: practice,
      ),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.t(context, 'study_preferences_saved'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t(context, 'study_preferences'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            AppStrings.t(context, 'how_much_study'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '$dailyMinutes minutes',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Slider(
            min: 15,
            max: 180,
            divisions: 11,
            value: dailyMinutes.toDouble(),
            label: '$dailyMinutes min',
            onChanged: (value) {
              setState(() {
                dailyMinutes = value.round();
              });
            },
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              AppStrings.t(context, 'weak_points'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(AppStrings.t(context, 'weak_points_subtitle')),
            value: weakPoints,
            onChanged: (value) {
              setState(() {
                weakPoints = value;
              });
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              AppStrings.t(context, 'lessons'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(AppStrings.t(context, 'lessons_subtitle')),
            value: lessons,
            onChanged: (value) {
              setState(() {
                lessons = value;
              });
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              AppStrings.t(context, 'practice'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(AppStrings.t(context, 'practice_subtitle')),
            value: practice,
            onChanged: (value) {
              setState(() {
                practice = value;
              });
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _save,
              child: Text(AppStrings.t(context, 'save')),
            ),
          ),
        ],
      ),
    );
  }
}
