import 'content_file_descriptor.dart';

/// The contract between the content repository and the app: one manifest that
/// lists every file a release ships with, plus its SHA-256 digest.
class ContentManifest {
  final String schemaVersion;

  final String contentVersion;

  final String updatedAt;

  final List<ContentFileDescriptor> files;

  const ContentManifest({
    required this.schemaVersion,
    required this.contentVersion,
    required this.updatedAt,
    required this.files,
  });

  /// The content collection a file belongs to, derived from its path.
  ///
  /// `subjects.json` and `subjects/mathematics.json` both belong to the
  /// `subjects` collection. `manifest.json` is not a collection.
  static String collectionOf(String path) {
    final first = path.split('/').first;
    final dot = first.indexOf('.');
    return dot == -1 ? first : first.substring(0, dot);
  }

  /// The descriptors of one collection, in manifest order.
  List<ContentFileDescriptor> filesForCollection(String collection) {
    return files
        .where((file) => collectionOf(file.path) == collection)
        .toList(growable: false);
  }

  factory ContentManifest.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'];

    if (rawFiles is! List) {
      throw const FormatException('Manifest field "files" must be an array.');
    }

    return ContentManifest(
      schemaVersion: json['schemaVersion'] as String,
      contentVersion: json['contentVersion'] as String,
      updatedAt: json['updatedAt'] as String,
      files: rawFiles
          .map(
            (item) => ContentFileDescriptor.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}
