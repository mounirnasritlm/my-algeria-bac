/// Severity of a single content-validation finding.
enum ContentIssueSeverity { error, warning }

/// One finding produced while validating a content bundle.
class ContentValidationIssue {
  const ContentValidationIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.collection,
    this.itemId,
  });

  final ContentIssueSeverity severity;

  /// Stable machine-readable code, e.g. `UNKNOWN_SUBJECT`.
  final String code;

  final String message;

  /// Which collection the finding belongs to (e.g. `lessons`).
  final String? collection;

  /// Which item inside the collection (its `id` when known).
  final String? itemId;

  bool get isError => severity == ContentIssueSeverity.error;

  bool get isWarning => severity == ContentIssueSeverity.warning;

  @override
  String toString() => '[$code] ($collection/$itemId) $message';
}

/// The aggregate outcome of validating one bundle.
class ContentValidationResult {
  const ContentValidationResult(this.issues);

  static const ContentValidationResult valid = ContentValidationResult([]);

  final List<ContentValidationIssue> issues;

  /// A bundle is valid when it has no error-severity findings. Warnings do
  /// not block it.
  bool get isValid => issues.every((issue) => !issue.isError);

  List<ContentValidationIssue> get errors =>
      issues.where((issue) => issue.isError).toList(growable: false);

  List<ContentValidationIssue> get warnings =>
      issues.where((issue) => issue.isWarning).toList(growable: false);
}
