import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_controller.dart';
import '../config/feature_flags.dart';
import '../data/app_database.dart';

/// Debug-only panel that surfaces runtime state and diagnostics.
///
/// Reachable only when [FeatureFlags.developerTools] is enabled, so it is
/// compiled into release builds but never surfaced to users. Text is
/// intentionally English: this is a developer tool, not product UI.
Future<void> showDeveloperMenu(BuildContext context, AppController? controller) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DeveloperMenu(controller: controller),
  );
}

class DeveloperMenu extends StatelessWidget {
  const DeveloperMenu({super.key, this.controller});

  final AppController? controller;

  static const _flags = <String, bool>{
    'remoteContentSync': FeatureFlags.remoteContentSync,
    'studyPreferences': FeatureFlags.studyPreferences,
    'developerTools': FeatureFlags.developerTools,
    'onboarding': FeatureFlags.onboarding,
  };

  String _diagnostics() {
    final flags = _flags.entries
        .map((e) => '${e.key}=${e.value}')
        .join(', ');
    final buffer = StringBuffer()
      ..writeln('Language: ${controller?.languageCode ?? '—'}')
      ..writeln('Theme: ${controller?.themePreference.name ?? '—'}')
      ..writeln('Profile saved: ${controller?.studentProfile != null}')
      ..writeln('Onboarding needed: ${controller?.needsOnboarding ?? false}')
      ..writeln('DB schema version: ${ProgressDatabase.databaseVersion}')
      ..write('Flags: $flags');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Developer tools',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 16),
            _sectionTitle(context, 'Runtime'),
            _row(context, 'Language', controller?.languageCode ?? '—'),
            _row(
              context,
              'Theme',
              controller?.themePreference.name ?? '—',
            ),
            _row(context, 'Profile saved', '${controller?.studentProfile != null}'),
            _row(context, 'Onboarding needed', '${controller?.needsOnboarding ?? false}'),
            const SizedBox(height: 12),
            _sectionTitle(context, 'Storage'),
            _row(context, 'DB schema version', '${ProgressDatabase.databaseVersion}'),
            const SizedBox(height: 12),
            _sectionTitle(context, 'Feature flags'),
            for (final entry in _flags.entries)
              _row(context, entry.key, '${entry.value}'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _diagnostics()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Diagnostics copied.')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy diagnostics'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
