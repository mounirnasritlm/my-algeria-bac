import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// In-memory [AssetBundle] that serves canned JSON content. Used to exercise
/// [JsonContentRepository] and the app shell in tests without real assets.
class FakeAssetBundle extends CachingAssetBundle {
  FakeAssetBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<ByteData> load(String key) async {
    final content = _assets[key];
    if (content == null) {
      throw FlutterError('Unable to load asset: $key');
    }
    return ByteData.sublistView(utf8.encode(content));
  }
}
