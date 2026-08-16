import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_algeria_bac/content/content_bundle.dart';
import 'package:my_algeria_bac/content/content_loader.dart';
import 'package:my_algeria_bac/content/content_service.dart';

import 'helpers/demo_content_assets.dart';

void main() {
  group('ContentValidator', () {
    test('accepts the demo bundle', () async {
      final loaded = await _load(_demoFiles());

      expect(loaded.isValid, isTrue);
      expect(loaded.bundle.subjects, hasLength(2));
      expect(loaded.bundle.questions, hasLength(5));
    });

    test('reports the unverified demo source as a warning, not an error', () async {
      final loaded = await _load(_demoFiles());

      expect(
        loaded.validation.warnings.map((issue) => issue.code),
        contains('UNVERIFIED_SOURCE'),
      );
      expect(loaded.validation.errors, isEmpty);
    });

    test('warns about empty optional collections but stays valid', () async {
      final loaded = await _load(_demoFiles());

      expect(
        loaded.validation.warnings.map((issue) => issue.code),
        contains('EMPTY_COLLECTION'),
      );
      expect(loaded.isValid, isTrue);
    });

    test('rejects duplicate ids', () async {
      final loaded = await _load(
        _mutate(
          _demoFiles(),
          'subjects.json',
          (items) => items.add(Map<String, dynamic>.from(items.first)),
        ),
      );

      expect(loaded.isValid, isFalse);
      expect(_codesOf(loaded), contains('DUPLICATE_ID'));
    });

    test('rejects a chapter pointing at an unknown subject', () async {
      final loaded = await _load(
        _mutate(
          _demoFiles(),
          'chapters.json',
          (items) => items.first['subjectId'] = 'ghost_subject',
        ),
      );

      expect(loaded.isValid, isFalse);
      expect(_codesOf(loaded), contains('UNKNOWN_SUBJECT'));
    });

    test('rejects a lesson pointing at an unknown source', () async {
      final loaded = await _load(
        _mutate(
          _demoFiles(),
          'lessons.json',
          (items) => items.first['sourceId'] = 'ghost_source',
        ),
      );

      expect(loaded.isValid, isFalse);
      expect(_codesOf(loaded), contains('UNKNOWN_SOURCE'));
    });

    test('rejects a question without a correct answer', () async {
      final loaded = await _load(
        _mutate(
          _demoFiles(),
          'questions.json',
          (items) => items.first.remove('correctIndex'),
        ),
      );

      expect(loaded.isValid, isFalse);
      expect(_codesOf(loaded), contains('MISSING_CORRECT_ANSWER'));
    });

    test('rejects a question with too few options', () async {
      final loaded = await _load(
        _mutate(
          _demoFiles(),
          'questions.json',
          (items) => items.first['options'] = ['only one'],
        ),
      );

      expect(loaded.isValid, isFalse);
      expect(_codesOf(loaded), contains('INVALID_OPTIONS'));
    });

    test('rejects an exam referencing an unknown question', () async {
      final loaded = await _load(
        _mutate(
          _demoFiles(),
          'exams.json',
          (items) {
            final sections =
                (items.first['sections'] as List).cast<Map<String, dynamic>>();
            sections.first['questionIds'] = ['ghost_question'];
          },
        ),
      );

      expect(loaded.isValid, isFalse);
      expect(_codesOf(loaded), contains('UNKNOWN_QUESTION'));
    });

    test('rejects a mismatched schema version', () async {
      final loaded = await _load(
        _mutateManifest(
          _demoFiles(),
          (manifest) => manifest['schemaVersion'] = '2.0.0',
        ),
      );

      expect(loaded.isValid, isFalse);
      expect(_codesOf(loaded), contains('UNSUPPORTED_SCHEMA_VERSION'));
    });

    test('rejects a question whose concept belongs to another lesson', () async {
      final loaded = await _load(
        _mutate(
          _demoFiles(),
          'questions.json',
          (items) {
            items.first['conceptId'] = 'function_domain';
            items.first['lessonId'] = 'math_function_definition';
          },
        ),
      );

      expect(loaded.isValid, isFalse);
      expect(_codesOf(loaded), contains('MISMATCHED_CONCEPT'));
    });
  });
}

Future<LoadedContent> _load(Map<String, String> files) {
  return ContentService(loader: _FakeLoader(files)).loadContent();
}

Set<String> _codesOf(LoadedContent loaded) =>
    {for (final issue in loaded.validation.issues) issue.code};

/// Builds the demo bundle keyed by content-relative paths.
Map<String, String> _demoFiles() {
  return {
    for (final entry in demoContentAssets.entries)
      if (entry.key.startsWith('assets/content/'))
        entry.key.replaceFirst('assets/content/', ''): entry.value,
  };
}

/// Returns a copy of [files] where [path] (a JSON list) was mutated by
/// [change].
Map<String, String> _mutate(
  Map<String, String> files,
  String path,
  void Function(List<Map<String, dynamic>> items) change,
) {
  final clone = Map<String, String>.from(files);
  final items =
      (jsonDecode(clone[path]!) as List).cast<Map<String, dynamic>>();
  change(items);
  clone[path] = jsonEncode(items);
  return clone;
}

/// Returns a copy of [files] where the manifest was mutated by [change].
Map<String, String> _mutateManifest(
  Map<String, String> files,
  void Function(Map<String, dynamic> manifest) change,
) {
  final clone = Map<String, String>.from(files);
  final manifest = jsonDecode(clone['manifest.json']!) as Map<String, dynamic>;
  change(manifest);
  clone['manifest.json'] = jsonEncode(manifest);
  return clone;
}

class _FakeLoader implements ContentLoader {
  _FakeLoader(this._files);

  final Map<String, String> _files;

  @override
  Future<bool> exists(String path) async => _files.containsKey(path);

  @override
  Future<String> loadFile(String path) async {
    final content = _files[path];
    if (content == null) {
      throw ContentNotFoundException(path);
    }
    return content;
  }
}
