import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_algeria_bac/config/content_config.dart';
import 'package:my_algeria_bac/content/content_loader.dart';
import 'package:my_algeria_bac/content/github_content_loader.dart';

void main() {
  const config = ContentConfig(
    githubOwner: 'owner',
    githubRepository: 'repo',
    githubBranch: 'main',
    contentPath: 'content',
  );

  group('GitHubContentLoader', () {
    test('loadFile fetches the expected raw URL', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://raw.githubusercontent.com/owner/repo/main/content/subjects.json',
        );
        return http.Response('[{"id": "mathematics"}]', 200);
      });

      final loader = GitHubContentLoader(config: config, client: client);
      expect(await loader.loadFile('subjects.json'), '[{"id": "mathematics"}]');
    });

    test('exists returns false for a 404', () async {
      final client = MockClient((_) async => http.Response('Not Found', 404));

      final loader = GitHubContentLoader(config: config, client: client);
      expect(await loader.exists('missing.json'), isFalse);
    });

    test('exists returns true for a 200', () async {
      final client = MockClient((_) async => http.Response('{}', 200));

      final loader = GitHubContentLoader(config: config, client: client);
      expect(await loader.exists('manifest.json'), isTrue);
    });

    test('loadFile throws ContentNotFoundException for a 404', () async {
      final client = MockClient((_) async => http.Response('Not Found', 404));

      final loader = GitHubContentLoader(config: config, client: client);
      expect(
        () => loader.loadFile('missing.json'),
        throwsA(isA<ContentNotFoundException>()),
      );
    });
  });
}
