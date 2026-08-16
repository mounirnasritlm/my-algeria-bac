import 'package:flutter/foundation.dart';

import '../data/content_repository.dart';
import '../models/content_status.dart';
import 'app_content_manager.dart';
import 'content_sync_result.dart';

/// Bridges the content pipeline to the UI.
///
/// Resolves the repository the app reads from (the validated on-device cache
/// when present, otherwise the bundled assets), runs background syncs, and
/// notifies listeners whenever the active repository or sync state changes.
///
/// The app boots from whichever source is available immediately
/// ([initialize]) and refreshes in the background via [syncNow]; a failed or
/// rejected sync never throws and never breaks the running app.
class ContentCoordinator extends ChangeNotifier {
  ContentCoordinator({required this.manager});

  final AppContentManager manager;

  ContentRepository? _repository;

  ContentStatus? _status;

  ContentSyncResult? _lastSync;

  bool _syncing = false;

  bool _disposed = false;

  /// The repository the app should read from right now.
  ContentRepository get repository {
    final repo = _repository;
    if (repo == null) {
      throw StateError('ContentCoordinator.initialize() was not awaited');
    }
    return repo;
  }

  /// Latest snapshot of the content state, or null before [initialize].
  ContentStatus? get status => _status;

  /// Outcome of the most recent sync, or null when none has finished yet.
  ContentSyncResult? get lastSync => _lastSync;

  /// Whether a sync is currently in progress.
  bool get syncing => _syncing;

  /// Resolves the repository and status from the current sources. Call once
  /// at startup (or after [syncNow] to re-read the sources).
  Future<void> initialize() async {
    _repository = await manager.activeRepository();
    _status = await manager.status();
    _notify();
  }

  Future<ContentSyncResult>? _inFlight;

  /// Runs one background sync. Never throws: on success the active repository
  /// and status are re-resolved and listeners are notified; on unexpected
  /// failure a [ContentSyncStatus.failed] result is recorded instead.
  ///
  /// A call while a sync is already running shares the in-flight run instead
  /// of starting a second one.
  Future<ContentSyncResult> syncNow() {
    final inFlight = _inFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final run = _runSync();
    _inFlight = run;
    return run.whenComplete(() {
      _inFlight = null;
    });
  }

  Future<ContentSyncResult> _runSync() async {
    _syncing = true;
    _notify();

    try {
      _lastSync = await manager.syncNow();
    } catch (error) {
      _lastSync = ContentSyncResult(
        status: ContentSyncStatus.failed,
        message: 'Unexpected sync failure: $error',
      );
    } finally {
      _syncing = false;
      _repository = await manager.activeRepository();
      _status = await manager.status();
      _notify();
    }

    return _lastSync!;
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
