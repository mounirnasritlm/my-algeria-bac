import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../l10n/app_strings.dart';
import '../models/student_profile.dart';

/// Collects or edits the small set of choices used to personalize the BAC
/// journey. It deliberately stores a target, not a prediction of exam score.
class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({
    super.key,
    required this.controller,
    this.editing = false,
  });

  final AppController controller;
  final bool editing;

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  static const _stepCount = 5;

  late BacStream _stream;
  late int _bacYear;
  late double _targetAverage;
  late String _languageCode;
  late int _dailyGoalMinutes;

  int _step = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.controller.studentProfile;
    _stream = profile?.stream ?? BacStream.experimentalSciences;
    _bacYear = profile?.bacYear ?? DateTime.now().year + 1;
    _targetAverage = profile?.targetAverage ?? 14;
    _languageCode = profile?.languageCode ?? 'ar';
    _dailyGoalMinutes = profile?.dailyGoalMinutes ?? 45;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.editing,
        title: Text(
          AppStrings.t(
            context,
            widget.editing ? 'profile_page_title' : 'onboarding_title',
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_step + 1) / _stepCount),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: _stepContent(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _previous,
                      child: Text(AppStrings.t(context, 'back')),
                    ),
                  ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _saving ? null : _next,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _step == _stepCount - 1
                                  ? widget.editing
                                      ? AppStrings.t(context, 'save_changes')
                                      : AppStrings.t(context, 'start_studying')
                                  : AppStrings.t(context, 'next'),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepContent(BuildContext context) {
    switch (_step) {
      case 0:
        return _choiceStep(
          title: AppStrings.t(context, 'onboarding_stream_title'),
          subtitle: AppStrings.t(context, 'onboarding_stream_subtitle'),
          child: DropdownButtonFormField<BacStream>(
            initialValue: _stream,
            decoration: InputDecoration(
              labelText: AppStrings.t(context, 'bac_stream_label'),
            ),
            items: [
              for (final stream in BacStream.values)
                DropdownMenuItem(
                  value: stream,
                  child: Text(_streamLabel(context, stream)),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _stream = value;
                });
              }
            },
          ),
        );
      case 1:
        final years = [
          for (var year = DateTime.now().year;
              year <= DateTime.now().year + 2;
              year++)
            year,
        ];
        return _choiceStep(
          title: AppStrings.t(context, 'onboarding_year_title'),
          subtitle: AppStrings.t(context, 'onboarding_year_subtitle'),
          child: DropdownButtonFormField<int>(
            initialValue: years.contains(_bacYear) ? _bacYear : years.first,
            decoration: InputDecoration(
              labelText: AppStrings.t(context, 'bac_year_label'),
            ),
            items: [
              for (final year in years)
                DropdownMenuItem(value: year, child: Text('$year')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _bacYear = value;
                });
              }
            },
          ),
        );
      case 2:
        return _choiceStep(
          title: AppStrings.t(context, 'onboarding_target_title'),
          subtitle: AppStrings.t(context, 'onboarding_target_subtitle'),
          child: Column(
            children: [
              Text(
                '${_targetAverage.toStringAsFixed(1)} / 20',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              Slider(
                min: 10,
                max: 20,
                divisions: 20,
                value: _targetAverage,
                label: _targetAverage.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _targetAverage = value;
                  });
                },
              ),
            ],
          ),
        );
      case 3:
        return _choiceStep(
          title: AppStrings.t(context, 'onboarding_language_title'),
          subtitle: AppStrings.t(context, 'onboarding_language_subtitle'),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _languageChip('fr', 'Français'),
              _languageChip('ar', 'العربية'),
              _languageChip('en', 'English'),
            ],
          ),
        );
      case 4:
        return _choiceStep(
          title: AppStrings.t(context, 'onboarding_goal_title'),
          subtitle: AppStrings.t(context, 'onboarding_goal_subtitle'),
          child: Column(
            children: [
              Text(
                '$_dailyGoalMinutes minutes',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              Slider(
                min: 15,
                max: 180,
                divisions: 11,
                value: _dailyGoalMinutes.toDouble(),
                label: '$_dailyGoalMinutes min',
                onChanged: (value) {
                  setState(() {
                    _dailyGoalMinutes = value.round();
                  });
                },
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _choiceStep({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Text(subtitle),
        const SizedBox(height: 32),
        child,
      ],
    );
  }

  Widget _languageChip(String code, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _languageCode == code,
      onSelected: (_) {
        setState(() {
          _languageCode = code;
        });
      },
    );
  }

  void _previous() {
    if (_step > 0) {
      setState(() {
        _step--;
      });
    }
  }

  void _next() {
    if (_step < _stepCount - 1) {
      setState(() {
        _step++;
      });
      return;
    }

    _save();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
    });

    await widget.controller.saveStudentProfile(
      StudentProfile(
        stream: _stream,
        bacYear: _bacYear,
        targetAverage: _targetAverage,
        languageCode: _languageCode,
        dailyGoalMinutes: _dailyGoalMinutes,
      ),
    );

    if (!mounted) {
      return;
    }

    if (widget.editing) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
      });
    }
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
}
