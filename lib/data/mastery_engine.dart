import '../models/concept_mastery.dart';
import '../models/weak_point.dart';

/// Pure revision-priority scoring. No I/O, no AI: the diagnosis is derived
/// directly from recorded attempts. Kept separate from the repository so it
/// can be unit-tested without a database.

/// How much to boost priority when a concept has not been practiced recently.
/// Returns 1.0 for never/30+ days ago, down to 0.0 for < 3 days ago.
double recencyPenalty(DateTime? lastAttemptAt, {DateTime? now}) {
  if (lastAttemptAt == null) {
    return 1.0;
  }

  final daysSince = (now ?? DateTime.now()).difference(lastAttemptAt).inDays;

  if (daysSince >= 30) {
    return 1.0;
  }

  if (daysSince >= 14) {
    return 0.75;
  }

  if (daysSince >= 7) {
    return 0.50;
  }

  if (daysSince >= 3) {
    return 0.25;
  }

  return 0.0;
}

/// How confident we are in the observed accuracy, based on sample size.
/// More attempts => the estimate is more reliable => higher confidence.
double confidenceFromAttempts(int attempts) {
  if (attempts >= 10) {
    return 1.0;
  }

  return attempts / 10;
}

/// Combined revision priority in [0, 1]. Higher means "revise first".
///
/// Weights are an initial heuristic, not a claim of pedagogical optimality:
/// accuracy (60%), recency (25%), confidence/sample size (15%).
double revisionPriority({
  required double accuracy,
  required DateTime? lastAttemptAt,
  required int attempts,
  DateTime? now,
}) {
  final accuracyScore = 1.0 - accuracy;
  final recency = recencyPenalty(lastAttemptAt, now: now);
  final confidence = confidenceFromAttempts(attempts);

  return (accuracyScore * 0.60) + (recency * 0.25) + (confidence * 0.15);
}

/// Human-readable reason shown alongside a recommendation.
String recommendationReason(ConceptMastery mastery) {
  final percent = (mastery.accuracy * 100).round();

  if (percent < 40) {
    return 'You are struggling with this concept.';
  }

  if (percent < 60) {
    return 'This concept needs more practice.';
  }

  if (percent < 75) {
    return 'You are improving, but more revision is useful.';
  }

  if (percent < 90) {
    return 'You are doing well. A review can make this stronger.';
  }

  return 'Keep this concept fresh.';
}

/// Recency-weighted mastery in [0, 1] computed from per-attempt outcomes in
/// chronological order (oldest first). Each attempt carries weight
/// `1 + 0.15 * index`, so recent performance dominates the estimate while a
/// long history of good work still anchors the score.
double weightedMastery(List<bool> correctResults) {
  var weightedCorrect = 0.0;
  var totalWeight = 0.0;

  for (var i = 0; i < correctResults.length; i++) {
    final weight = 1.0 + (i * 0.15);
    totalWeight += weight;
    if (correctResults[i]) {
      weightedCorrect += weight;
    }
  }

  if (totalWeight == 0) {
    return 0;
  }

  return (weightedCorrect / totalWeight).clamp(0.0, 1.0);
}

/// Priority bucket for the Weak Point Hunter. Uses [weightedMastery], never
/// the raw accuracy, and is only meaningful once [ConceptMastery.hasEnoughEvidence]
/// is true — callers must filter before classifying.
WeakPointPriority weakPointPriorityFor(double mastery) {
  if (mastery < 0.40) {
    return WeakPointPriority.critical;
  }
  if (mastery < 0.55) {
    return WeakPointPriority.high;
  }
  if (mastery < 0.70) {
    return WeakPointPriority.medium;
  }
  return WeakPointPriority.low;
}

/// Builds the evidence-backed weak-point list: only concepts with enough
/// attempts are candidates, classified by weighted mastery and sorted worst
/// first so the most critical concept leads the list.
List<WeakPoint> weakPointsFromMastery(List<ConceptMastery> mastery) {
  final result = <WeakPoint>[];

  for (final item in mastery) {
    if (!item.hasEnoughEvidence) {
      continue;
    }

    result.add(
      WeakPoint(
        conceptId: item.conceptId,
        lessonId: item.lessonId,
        mastery: item.mastery,
        attempts: item.attempts,
        priority: weakPointPriorityFor(item.mastery),
      ),
    );
  }

  result.sort((a, b) => a.mastery.compareTo(b.mastery));

  return result;
}
