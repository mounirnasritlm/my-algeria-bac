import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_algeria_bac/models/content_manifest.dart';
import 'package:my_algeria_bac/services/content/content_hash_service.dart';
import 'package:my_algeria_bac/services/content/content_release_validator.dart';

void main() {
  const validator = ContentReleaseValidator(ContentHashService());

  String hashOf(String content) =>
      sha256.convert(utf8.encode(content)).toString();

  Map<String, String> demoFiles() => {
        'subjects.json': '[{"id": "mathematics"}]',
        'chapters.json': '[]',
      };

  ContentManifest demoManifest(
    Map<String, String> files, {
    String schema = '1.0.0',
  }) {
    return ContentManifest.fromJson({
      'schemaVersion': schema,
      'contentVersion': '1.0.0',
      'updatedAt': '2026-08-15T00:00:00Z',
      'files': [
        {
          'path': 'subjects.json',
          'sha256': hashOf(files['subjects.json']!),
          'required': true,
        },
        {
          'path': 'chapters.json',
          'sha256': hashOf(files['chapters.json']!),
          'required': false,
        },
      ],
    });
  }

  test('accepts a release whose files match their digests', () async {
    final files = demoFiles();
    final result = await validator.validateRelease(
      manifest: demoManifest(files),
      fileLoader: (path) async => files[path],
    );

    expect(result.compatible, isTrue);
    expect(result.issues, isEmpty);
  });

  test('rejects a file whose bytes do not match its digest', () async {
    final base = demoFiles();
    final manifest = demoManifest(base);
    final files = Map<String, String>.from(base);
    files['subjects.json'] = '[{"id": "tampered"}]';

    final result = await validator.validateRelease(
      manifest: manifest,
      fileLoader: (path) async => files[path],
    );

    expect(result.compatible, isFalse);
    expect(result.issues.single.path, 'subjects.json');
    expect(result.issues.single.reason, 'digest mismatch');
  });

  test('rejects a missing required file', () async {
    final base = demoFiles();
    final manifest = demoManifest(base);
    final files = Map<String, String>.from(base);
    files.remove('subjects.json');

    final result = await validator.validateRelease(
      manifest: manifest,
      fileLoader: (path) async => files[path],
    );

    expect(result.compatible, isFalse);
    expect(result.issues.single.reason, 'file is missing');
  });

  test('allows an optional file to be absent', () async {
    final base = demoFiles();
    final manifest = demoManifest(base);
    final files = Map<String, String>.from(base);
    files.remove('chapters.json');

    final result = await validator.validateRelease(
      manifest: manifest,
      fileLoader: (path) async => files[path],
    );

    expect(result.compatible, isTrue);
  });

  test('rejects a schema-incompatible manifest', () async {
    final files = demoFiles();
    final result = await validator.validateRelease(
      manifest: demoManifest(files, schema: '2.0.0'),
      fileLoader: (path) async => files[path],
    );

    expect(result.compatible, isFalse);
    expect(result.issues.single.path, 'manifest.json');
  });

  test('rejects a malformed schema version', () async {
    final files = demoFiles();
    final result = await validator.validateRelease(
      manifest: demoManifest(files, schema: 'not.a.version'),
      fileLoader: (path) async => files[path],
    );

    expect(result.compatible, isFalse);
    expect(result.issues.single.reason, contains('malformed'));
  });
}
