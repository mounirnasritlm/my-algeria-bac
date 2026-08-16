import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Recomputes the SHA-256 digests of every content file and rewrites
/// `manifest.json` in place.
///
/// Usage: `dart run tool/generate_manifest_hashes.dart <contentDir>`
/// (defaults to `assets/content`). The manifest's existing schemaVersion,
/// contentVersion and updatedAt are preserved; only the `files` digests are
/// refreshed. contentVersion must be bumped by the content author whenever
/// the bundle changes.
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

  final manifestRaw = await manifestFile.readAsString();
  final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;

  if (manifest['schemaVersion'] is! String ||
      manifest['contentVersion'] is! String) {
    stderr.writeln('manifest.json is missing schemaVersion/contentVersion.');
    exit(1);
  }

  final rawFiles = manifest['files'];
  if (rawFiles is! List) {
    stderr.writeln('manifest.json "files" must be an array.');
    exit(1);
  }

  final updatedFiles = <Map<String, dynamic>>[];
  for (final entry in rawFiles) {
    final file = Map<String, dynamic>.from(entry as Map);
    final path = file['path'] as String;

    final contentFile = File('${contentDir.path}/$path');
    if (!await contentFile.exists()) {
      stderr.writeln('Missing content file listed in manifest: $path');
      exit(1);
    }

    final bytes = await contentFile.readAsBytes();
    file['sha256'] = sha256.convert(bytes).toString();
    updatedFiles.add(file);
  }

  manifest['updatedAt'] = DateTime.now().toUtc().toIso8601String();
  manifest['files'] = updatedFiles;

  const encoder = JsonEncoder.withIndent('  ');
  await manifestFile.writeAsString('${encoder.convert(manifest)}\n');

  stdout.writeln(
      'Updated ${contentDir.path}/manifest.json '
      '(${updatedFiles.length} files, version ${manifest['contentVersion']}).');
}
