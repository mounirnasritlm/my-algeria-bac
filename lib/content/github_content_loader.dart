import 'package:http/http.dart' as http;

import '../config/content_config.dart';
import 'content_loader.dart';

/// Fetches content files from the raw GitHub URLs derived from a
/// [ContentConfig].
class GitHubContentLoader implements ContentLoader {
  GitHubContentLoader({ContentConfig? config, http.Client? client})
      : _config = config ?? const ContentConfig(),
        _client = client ?? http.Client();

  final ContentConfig _config;

  final http.Client _client;

  @override
  Future<bool> exists(String path) async {
    final response = await _get(path);
    return response.statusCode == 200;
  }

  @override
  Future<String> loadFile(String path) async {
    final response = await _get(path);
    if (response.statusCode != 200) {
      throw ContentNotFoundException(path, statusCode: response.statusCode);
    }
    return response.body;
  }

  Future<http.Response> _get(String path) {
    return _client
        .get(_config.rawUrlFor(path))
        .timeout(_config.networkTimeout);
  }
}
