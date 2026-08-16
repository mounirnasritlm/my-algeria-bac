import 'package:flutter/material.dart';

import '../content/content_coordinator.dart';
import '../content/content_sync_result.dart';
import '../l10n/app_strings.dart';

/// Surfaces the content pipeline to the user: which content version is in
/// effect, where it comes from, when it was last checked, and the manual
/// actions (check for updates / clear the cached release).
class ContentSettingsPage extends StatefulWidget {
  const ContentSettingsPage({super.key, required this.coordinator});

  final ContentCoordinator coordinator;

  @override
  State<ContentSettingsPage> createState() => _ContentSettingsPageState();
}

class _ContentSettingsPageState extends State<ContentSettingsPage> {
  bool _busy = false;
  String? _bundledVersion;

  @override
  void initState() {
    super.initState();
    widget.coordinator.addListener(_onCoordinatorChanged);
    _loadBundledVersion();
  }

  @override
  void dispose() {
    widget.coordinator.removeListener(_onCoordinatorChanged);
    super.dispose();
  }

  void _onCoordinatorChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadBundledVersion() async {
    final version = await widget.coordinator.repository.getContentVersion();
    if (mounted) {
      setState(() => _bundledVersion = version);
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _busy = true);
    await widget.coordinator.syncNow();
    await _loadBundledVersion();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.t(context, 'content_clear_confirm_title')),
          content: Text(AppStrings.t(context, 'content_clear_confirm_body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppStrings.t(context, 'back')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppStrings.t(context, 'content_clear_cache')),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    setState(() => _busy = true);
    await widget.coordinator.manager.clearCache();
    await widget.coordinator.initialize();
    await _loadBundledVersion();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.t(context, 'content_cleared'))),
    );
  }

  String _displayVersion() {
    final cached = widget.coordinator.status?.version;
    if (cached != null) {
      return cached;
    }
    return _bundledVersion ?? '—';
  }

  String _statusText() {
    if (_busy || widget.coordinator.syncing) {
      return AppStrings.t(context, 'content_checking');
    }
    final lastSync = widget.coordinator.lastSync;
    if (lastSync == null) {
      return '';
    }
    final version = _displayVersion();
    final usingCached = widget.coordinator.status?.usingCachedContent ?? false;
    switch (lastSync.status) {
      case ContentSyncStatus.upToDate:
        return usingCached
            ? AppStrings.t(context, 'banner_content_up_to_date', args: [version])
            : AppStrings.t(context, 'banner_up_to_date');
      case ContentSyncStatus.updated:
        return AppStrings.t(context, 'banner_content_updated', args: [version]);
      case ContentSyncStatus.firstInstall:
        return AppStrings.t(
          context,
          'banner_content_downloaded',
          args: [version],
        );
      case ContentSyncStatus.offlineUsingCache:
        return usingCached
            ? AppStrings.t(context, 'banner_offline_cached', args: [version])
            : AppStrings.t(context, 'banner_offline_bundled');
      case ContentSyncStatus.rejectedInvalidUpdate:
        return usingCached
            ? AppStrings.t(
                context,
                'banner_update_rejected_cached',
                args: [version],
              )
            : AppStrings.t(context, 'banner_update_rejected_bundled');
      case ContentSyncStatus.failed:
        return AppStrings.t(context, 'content_sync_failed');
    }
  }

  String _lastCheckedText() {
    final checkedAt = widget.coordinator.lastSync?.checkedAt;
    if (checkedAt == null) {
      return AppStrings.t(context, 'content_never_checked');
    }
    final local = checkedAt.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final usingCached = widget.coordinator.status?.usingCachedContent ?? false;
    final statusText = _statusText();

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t(context, 'content_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Card(
            child: Column(
              children: [
                _row(
                  context,
                  AppStrings.t(context, 'content_version'),
                  _displayVersion(),
                ),
                _divider(context),
                _row(
                  context,
                  AppStrings.t(context, 'content_source'),
                  AppStrings.t(
                    context,
                    usingCached
                        ? 'content_source_cached'
                        : 'content_source_bundled',
                  ),
                ),
                _divider(context),
                _row(
                  context,
                  AppStrings.t(context, 'content_last_checked'),
                  _lastCheckedText(),
                ),
              ],
            ),
          ),
          if (statusText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              statusText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _busy ? null : _checkForUpdates,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(
                _busy
                    ? AppStrings.t(context, 'content_checking')
                    : AppStrings.t(context, 'content_check_updates'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _clearCache,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: Text(AppStrings.t(context, 'content_clear_cache')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        label,
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}
