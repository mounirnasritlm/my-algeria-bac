import 'package:flutter/services.dart';

import 'content_loader.dart';

/// Serves content from the bundled Flutter assets.
///
/// A content-relative path like `manifest.json` is resolved to
/// `assets/content/manifest.json`.
class AssetContentLoader implements ContentLoader {
  AssetContentLoader({AssetBundle? assetBundle, this.prefix = 'assets/content/'})
      : _bundle = assetBundle ?? rootBundle;

  final AssetBundle _bundle;

  final String prefix;

  String _fullPath(String path) => '$prefix$path';

  @override
  Future<bool> exists(String path) async {
    try {
      await _bundle.loadString(_fullPath(path));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> loadFile(String path) async {
    final content = await _bundle.loadString(_fullPath(path));
    if (content.isEmpty) {
      throw ContentNotFoundException(path);
    }
    return content;
  }
}
