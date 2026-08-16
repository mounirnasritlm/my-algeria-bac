import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Verifies that every file listed in `manifest.json` exists on disk and
/// matches its SHA-256 digest.
///
/// Usage: `dart run tool/validate_content.dart <contentDir>`
/// (defaults to `assets/content`).
void main(List<String> args) async {
  final contentDir =
      Directory(args.isNotEmpty ? args.first : 'assets/content');

  if (!await contentDir.exists()) {
    stderr.writeln('Content directory not found: ${contentDir.path}');
    exit(1);
  }

  final manifestFile = File('${contentDir.path}/manifest.json');
  if (!await manifestFile.exists()) {
    stderr.writeln('manifest.json not found in ${contentDir.path}');
    exit(1);
  }

  final manifest = jsonDecode(await manifestFile.readAsString())
      as Map<String, dynamic>;

  final files = manifest['files'];
  if (files is! List) {
    stderr.writeln('manifest.json "files" must be an array.');
    exit(1);
  }

  var failures = 0;
  for (final entry in files) {
    final file = Map<String, dynamic>.from(entry as Map);
    final path = file['path'] as String;
    final expected = file['sha256'] as String;

    final contentFile = File('${contentDir.path}/$path');
    if (!await contentFile.exists()) {
      stderr.writeln('MISSING  $path');
      failures++;
      continue;
    }

    final actual = sha256.convert(await contentFile.readAsBytes()).toString();
    if (actual != expected) {
      stderr.writeln('CORRUPT  $path');
      failures++;
    } else {
      stdout.writeln('ok       $path');
    }
  }

  if (failures > 0) {
    stderr.writeln('$failures file(s) failed verification.');
    exit(1);
  }
  stdout.writeln('All ${files.length} files verified.');
}
