import '../services/content/content_release_validator.dart';

/// Outcome of one content synchronization run.
enum ContentSyncStatus {
  /// No cache existed before and the bundle was installed successfully.
  firstInstall,

  /// The cache already holds the latest remote version; nothing was done.
  upToDate,

  /// A previous bundle was replaced by a newer, valid one.
  updated,

  /// The remote was unreachable; the previous cache stays in use.
  offlineUsingCache,

  /// The remote bundle was reached but failed validation; the previous cache
  /// stays in use.
  rejectedInvalidUpdate,

  /// Nothing could be installed (no cache and the remote failed).
  failed,
}

/// The result of a [ContentSyncStatus] run, with the versions involved and,
/// when the bundle was rejected, the validation findings.
class ContentSyncResult {
  const ContentSyncResult({
    required this.status,
    this.currentVersion,
    this.previousVersion,
    this.message,
    this.validation,
  });

  final ContentSyncStatus status;

  /// Content version now in effect (null when nothing is available).
  final String? currentVersion;

  /// Content version that was in effect before this run.
  final String? previousVersion;

  final String? message;

  /// Set when the remote bundle failed validation.
  final ContentReleaseValidationResult? validation;
}
