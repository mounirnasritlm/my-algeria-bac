import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

/// Computes SHA-256 digests of content and verifies files against a manifest.
class ContentHashService {
  const ContentHashService();

  String _sha256OfBytes(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  Future<String> sha256OfBytes(Uint8List bytes) async {
    return _sha256OfBytes(bytes);
  }

  Future<String> sha256OfString(String content) async {
    return _sha256OfBytes(utf8.encode(content));
  }

  /// Fetches [bytesLoader] output and hashes it in one pass.
  ///
  /// [bytesLoader] is lazily called exactly once; failures are not caught here
  /// and surface to the caller.
  Future<String> sha256FromLoader(
    Future<Uint8List> Function() bytesLoader,
  ) async {
    final bytes = await bytesLoader();
    return _sha256OfBytes(bytes);
  }

  /// Whether [path]'s bytes match its expected digest.
  ///
  /// A false result does not throw: callers decide whether a mismatch is fatal.
  Future<bool> matchesDescriptor({
    required Future<Uint8List> Function() bytesLoader,
    required String expectedSha256,
  }) async {
    try {
      final actual = await sha256FromLoader(bytesLoader);
      return actual.toLowerCase() == expectedSha256.toLowerCase();
    } on PlatformException {
      return false;
    }
  }
}
