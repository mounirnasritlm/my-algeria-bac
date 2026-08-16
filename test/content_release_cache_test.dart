import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_algeria_bac/content/content_release_cache.dart';

void main() {
  late Directory tempDir;
  late ContentReleaseCache cache;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('release_cache_test');
    cache = ContentReleaseCache(baseDirectory: tempDir.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('has no active release before anything is activated', () async {
    expect(await cache.hasActive(), isFalse);
    expect(await cache.activeVersion(), isNull);
    expect(await cache.readActiveFile('subjects.json'), isNull);
  });

  test('staging is invisible until activation', () async {
    await cache.stageRelease(version: '0.1.0', files: {
      'manifest.json': '{"contentVersion": "0.1.0"}',
      'subjects.json': '[]',
    });

    expect(await cache.hasActive(), isFalse);
    expect(await cache.readActiveFile('subjects.json'), isNull);

    await cache.activateVersion('0.1.0');

    expect(await cache.hasActive(), isTrue);
    expect(await cache.activeVersion(), '0.1.0');
    expect(await cache.readActiveFile('subjects.json'), '[]');
    expect(await cache.readActiveFile('manifest.json'), '{"contentVersion": "0.1.0"}');
  });

  test('a swap replaces the active release and drops the old one', () async {
    await cache.stageRelease(version: '0.1.0', files: {'data.json': 'one'});
    await cache.activateVersion('0.1.0');

    await cache.stageRelease(version: '0.2.0', files: {'data.json': 'two'});
    await cache.activateVersion('0.2.0');

    expect(await cache.activeVersion(), '0.2.0');
    expect(await cache.readActiveFile('data.json'), 'two');
  });

  test('a missing staged release cannot be activated', () async {
    expect(
      () => cache.activateVersion('0.1.0'),
      throwsA(isA<StateError>()),
    );
  });

  test('clear removes everything', () async {
    await cache.stageRelease(version: '0.1.0', files: {'data.json': 'x'});
    await cache.activateVersion('0.1.0');

    await cache.clear();

    expect(await cache.hasActive(), isFalse);
    expect(await cache.activeVersion(), isNull);
  });

  test('clearStaging removes staged releases without touching active', () async {
    await cache.stageRelease(version: '0.1.0', files: {'data.json': 'one'});
    await cache.activateVersion('0.1.0');
    await cache.stageRelease(version: '0.2.0', files: {'data.json': 'two'});

    await cache.clearStaging();

    expect(await cache.activeVersion(), '0.1.0');
    expect(await cache.readActiveFile('data.json'), 'one');
  });

  test('staging again for the same version replaces the previous stage', () async {
    await cache.stageRelease(version: '0.1.0', files: {'data.json': 'first'});
    await cache.stageRelease(version: '0.1.0', files: {'data.json': 'second'});
    await cache.activateVersion('0.1.0');

    expect(await cache.readActiveFile('data.json'), 'second');
  });
}
