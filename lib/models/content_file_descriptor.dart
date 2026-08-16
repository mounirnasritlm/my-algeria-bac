/// One file of a content release, with the SHA-256 digest that must match.
class ContentFileDescriptor {
  const ContentFileDescriptor({
    required this.path,
    required this.sha256,
    required this.required,
  });

  /// Content-relative path (e.g. `subjects.json` or `subjects/mathematics.json`).
  final String path;

  /// Expected lowercase SHA-256 digest of the file bytes.
  final String sha256;

  /// Whether the app can function without this file. Optional files (e.g. an
  /// empty teachers pack) may be absent from a source; required files may not.
  final bool required;

  factory ContentFileDescriptor.fromJson(Map<String, dynamic> json) {
    return ContentFileDescriptor(
      path: json['path'] as String,
      sha256: json['sha256'] as String,
      required: json['required'] as bool? ?? true,
    );
  }
}
