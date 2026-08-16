import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/content_manifest.dart';
import '../../config/content_schema_config.dart';
import 'content_hash_service.dart';

/// One file that failed release validation, and why.
class ContentReleaseIssue {
  const ContentReleaseIssue({required this.path, required this.reason});

  final String path;

  final String reason;

  @override
  String toString() => '$path: $reason';
}

/// The outcome of validating a candidate release before it is cached.
class ContentReleaseValidationResult {
  const ContentReleaseValidationResult({
    required this.releaseCompatible,
    required this.issues,
  });

  /// True when the manifest is schema-compatible AND all files that must be
  /// present are present and match their digests.
  final bool releaseCompatible;

  /// Descriptions of every missing, extra, or corrupt file (excludes
  /// `manifest.json` itself, which is assumed to be trusted at this stage).
  final List<ContentReleaseIssue> issues;

  bool get compatible => releaseCompatible;
}

/// Verifies that a downloaded release is schema-compatible and that every
/// file bytes match its manifest digest, before anything is activated.
///
/// The source is assumed to be transport-secured (HTTPS + server checksum);
/// the manifest itself is not re-signed here.
class ContentReleaseValidator {
  const ContentReleaseValidator(this._hashService);

  final ContentHashService _hashService;

  Future<ContentReleaseValidationResult> validateRelease({
    required ContentManifest manifest,
    required Future<String?> Function(String path) fileLoader,
  }) async {
    final issues = <ContentReleaseIssue>[];

    try {
      if (!ContentSchemaConfig.isCompatible(manifest.schemaVersion)) {
        return ContentReleaseValidationResult(
          releaseCompatible: false,
          issues: [
            ContentReleaseIssue(
              path: 'manifest.json',
              reason:
                  'schema ${manifest.schemaVersion} is incompatible with app '
                  '${ContentSchemaConfig.supportedSchemaVersion}',
            ),
          ],
        );
      }
    } on FormatException {
      return ContentReleaseValidationResult(
        releaseCompatible: false,
        issues: [
          ContentReleaseIssue(
            path: 'manifest.json',
            reason: 'schema ${manifest.schemaVersion} is malformed',
          ),
        ],
      );
    }

    var hasFailure = false;

    for (final file in manifest.files) {
      if (!file.required) {
        continue;
      }

      String? content;
      try {
        content = await fileLoader(file.path);
      } on PlatformException {
        content = null;
      }

      if (content == null) {
        issues.add(
          ContentReleaseIssue(path: file.path, reason: 'file is missing'),
        );
        hasFailure = true;
        continue;
      }

      final present = content;
      final matches = await _hashService.matchesDescriptor(
        bytesLoader: () => Future.value(Uint8List.fromList(utf8.encode(present))),
        expectedSha256: file.sha256,
      );

      if (!matches) {
        issues.add(
          ContentReleaseIssue(path: file.path, reason: 'digest mismatch'),
        );
        hasFailure = true;
      }
    }

    return ContentReleaseValidationResult(
      releaseCompatible: !hasFailure,
      issues: issues,
    );
  }
}
