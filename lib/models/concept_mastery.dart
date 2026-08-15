enum MasteryStatus {
  notStarted,
  learning,
  developing,
  strong,
  mastered,
}

class ConceptMastery {
  final String conceptId;
  final String lessonId;
  final int attempts;
  final int correct;

  /// Recency-weighted success rate (0..1): recent attempts carry more weight
  /// than old ones, so a concept the student just started fixing is no longer
  /// called weak forever on stale data.
  final double mastery;

  /// Plain ratio of correct / attempts, kept for dashboards that want the
  /// raw figure. Classification uses [mastery], not [accuracy].
  final double accuracy;
  final MasteryStatus status;
  final DateTime? lastAttemptAt;

  const ConceptMastery({
    required this.conceptId,
    required this.lessonId,
    required this.attempts,
    required this.correct,
    required this.mastery,
    required this.accuracy,
    required this.status,
    required this.lastAttemptAt,
  });

  int get incorrect => attempts - correct;

  /// No verdict until we have a minimum amount of evidence. One fluke answer
  /// never labels a concept as weak.
  bool get hasEnoughEvidence => attempts >= 3;

  bool get isCritical => hasEnoughEvidence && mastery < 0.40;

  bool get needsWork => hasEnoughEvidence && mastery >= 0.40 && mastery < 0.70;

  bool get isStrong => hasEnoughEvidence && mastery >= 0.85;

  /// Plain-language level used by the Weak Point Hunter screen.
  String get level {
    if (!hasEnoughEvidence) {
      return 'insufficient_data';
    }
    if (mastery < 0.40) {
      return 'critical';
    }
    if (mastery < 0.70) {
      return 'needs_work';
    }
    if (mastery < 0.85) {
      return 'review';
    }
    return 'strong';
  }

  bool get needsReview {
    return status == MasteryStatus.learning ||
        status == MasteryStatus.developing;
  }

  bool get isWeak {
    return hasEnoughEvidence && mastery < 0.60;
  }
}

/// Maps observed accuracy to a mastery bucket.
///
/// These thresholds are an initial product heuristic, not a claim of
/// pedagogical optimality. They can be tuned from real student performance.
MasteryStatus masteryStatusFromAccuracy(double accuracy, int attempts) {
  if (attempts == 0) {
    return MasteryStatus.notStarted;
  }

  if (accuracy >= 0.90) {
    return MasteryStatus.mastered;
  }

  if (accuracy >= 0.75) {
    return MasteryStatus.strong;
  }

  if (accuracy >= 0.60) {
    return MasteryStatus.developing;
  }

  return MasteryStatus.learning;
}
