import 'package:flutter_test/flutter_test.dart';

import 'package:my_algeria_bac/data/mastery_engine.dart';
import 'package:my_algeria_bac/models/concept_mastery.dart';
import 'package:my_algeria_bac/models/weak_point.dart';

void main() {
  group('masteryStatusFromAccuracy', () {
    test('no attempts means not started', () {
      expect(masteryStatusFromAccuracy(0, 0), MasteryStatus.notStarted);
    });

    test('buckets by accuracy', () {
      expect(masteryStatusFromAccuracy(0.50, 3), MasteryStatus.learning);
      expect(masteryStatusFromAccuracy(0.60, 3), MasteryStatus.developing);
      expect(masteryStatusFromAccuracy(0.74, 3), MasteryStatus.developing);
      expect(masteryStatusFromAccuracy(0.75, 3), MasteryStatus.strong);
      expect(masteryStatusFromAccuracy(0.89, 3), MasteryStatus.strong);
      expect(masteryStatusFromAccuracy(0.90, 3), MasteryStatus.mastered);
      expect(masteryStatusFromAccuracy(1.0, 3), MasteryStatus.mastered);
    });
  });

  group('recencyPenalty', () {
    final now = DateTime(2026, 8, 14);

    test('never attempted returns 1.0', () {
      expect(recencyPenalty(null, now: now), 1.0);
    });

    test('30+ days ago returns 1.0', () {
      expect(
        recencyPenalty(now.subtract(const Duration(days: 40)), now: now),
        1.0,
      );
    });

    test('buckets by days since last attempt', () {
      expect(
        recencyPenalty(now.subtract(const Duration(days: 20)), now: now),
        0.75,
      );
      expect(
        recencyPenalty(now.subtract(const Duration(days: 10)), now: now),
        0.50,
      );
      expect(
        recencyPenalty(now.subtract(const Duration(days: 4)), now: now),
        0.25,
      );
      expect(
        recencyPenalty(now.subtract(const Duration(days: 1)), now: now),
        0.0,
      );
    });
  });

  group('confidenceFromAttempts', () {
    test('scales with attempts up to 10', () {
      expect(confidenceFromAttempts(0), 0.0);
      expect(confidenceFromAttempts(5), 0.5);
      expect(confidenceFromAttempts(10), 1.0);
      expect(confidenceFromAttempts(25), 1.0);
    });
  });

  group('revisionPriority', () {
    final now = DateTime(2026, 8, 14);

    test('weak + stale + confident ranks highest', () {
      final staleAndWrong = revisionPriority(
        accuracy: 0.0,
        lastAttemptAt: now.subtract(const Duration(days: 40)),
        attempts: 10,
        now: now,
      );
      final freshAndRight = revisionPriority(
        accuracy: 1.0,
        lastAttemptAt: now,
        attempts: 10,
        now: now,
      );

      expect(staleAndWrong, greaterThan(freshAndRight));
    });

    test('higher priority for lower accuracy at same recency', () {
      final weak = revisionPriority(
        accuracy: 0.3,
        lastAttemptAt: now.subtract(const Duration(days: 1)),
        attempts: 4,
        now: now,
      );
      final strong = revisionPriority(
        accuracy: 0.9,
        lastAttemptAt: now.subtract(const Duration(days: 1)),
        attempts: 4,
        now: now,
      );

      expect(weak, greaterThan(strong));
    });
  });

  group('recommendationReason', () {
    ConceptMastery mastery(double accuracy) {
      return ConceptMastery(
        conceptId: 'c',
        lessonId: 'l',
        attempts: 5,
        correct: (accuracy * 5).round(),
        mastery: accuracy,
        accuracy: accuracy,
        status: masteryStatusFromAccuracy(accuracy, 5),
        lastAttemptAt: null,
      );
    }

    test('matches the accuracy bands', () {
      expect(
        recommendationReason(mastery(0.2)),
        'You are struggling with this concept.',
      );
      expect(
        recommendationReason(mastery(0.5)),
        'This concept needs more practice.',
      );
      expect(
        recommendationReason(mastery(0.65)),
        'You are improving, but more revision is useful.',
      );
      expect(
        recommendationReason(mastery(0.8)),
        'You are doing well. A review can make this stronger.',
      );
      expect(
        recommendationReason(mastery(0.95)),
        'Keep this concept fresh.',
      );
    });
  });

  group('weightedMastery', () {
    test('empty history scores zero', () {
      expect(weightedMastery([]), 0);
    });

    test('all correct is 1.0, all wrong is 0.0', () {
      expect(weightedMastery([true, true, true, true]), 1.0);
      expect(weightedMastery([false, false, false]), 0.0);
    });

    test('recent correct answers outweigh early ones', () {
      final improving = weightedMastery([false, false, true, true]);
      final regressing = weightedMastery([true, true, false, false]);

      expect(improving, greaterThan(regressing));
    });

    test('single result reflects the outcome', () {
      expect(weightedMastery([true]), 1.0);
      expect(weightedMastery([false]), 0.0);
    });
  });

  group('weakPointPriorityFor', () {
    test('maps mastery bands to priorities', () {
      expect(weakPointPriorityFor(0.0), WeakPointPriority.critical);
      expect(weakPointPriorityFor(0.39), WeakPointPriority.critical);
      expect(weakPointPriorityFor(0.40), WeakPointPriority.high);
      expect(weakPointPriorityFor(0.54), WeakPointPriority.high);
      expect(weakPointPriorityFor(0.55), WeakPointPriority.medium);
      expect(weakPointPriorityFor(0.69), WeakPointPriority.medium);
      expect(weakPointPriorityFor(0.70), WeakPointPriority.low);
      expect(weakPointPriorityFor(0.99), WeakPointPriority.low);
    });
  });

  group('weakPointsFromMastery', () {
    ConceptMastery item(
      String id, {
      required double mastery,
      double accuracy = 0.5,
      int attempts = 5,
    }) {
      return ConceptMastery(
        conceptId: id,
        lessonId: 'lesson_$id',
        attempts: attempts,
        correct: (accuracy * attempts).round(),
        mastery: mastery,
        accuracy: accuracy,
        status: masteryStatusFromAccuracy(accuracy, attempts),
        lastAttemptAt: null,
      );
    }

    test('excludes concepts without enough evidence', () {
      final weak = weakPointsFromMastery(
        [
          item('no_evidence', mastery: 0.0, attempts: 1),
          item('single_fluke', mastery: 0.0, attempts: 2),
          item('evidenced', mastery: 0.3),
        ],
      );

      expect(weak.map((w) => w.conceptId), ['evidenced']);
    });

    test('sorts worst first', () {
      final weak = weakPointsFromMastery(
        [
          item('ok', mastery: 0.75),
          item('bad', mastery: 0.25),
          item('worse', mastery: 0.10),
        ],
      );

      expect(weak.map((w) => w.conceptId), ['worse', 'bad', 'ok']);
    });

    test('classifies from weighted mastery, not raw accuracy', () {
      final weak = weakPointsFromMastery(
        [
          item('sneaky', mastery: 0.35, accuracy: 0.9),
        ],
      );

      expect(weak.single.priority, WeakPointPriority.critical);
    });

    test('carries the lesson id needed to train the weakness', () {
      final weak = weakPointsFromMastery([item('target', mastery: 0.5)]);

      expect(weak.single.lessonId, 'lesson_target');
    });
  });

  group('ConceptMastery evidence rules', () {
    ConceptMastery item({
      required double mastery,
      required int attempts,
    }) {
      return ConceptMastery(
        conceptId: 'c',
        lessonId: 'l',
        attempts: attempts,
        correct: 0,
        mastery: mastery,
        accuracy: 0.0,
        status: MasteryStatus.learning,
        lastAttemptAt: null,
      );
    }

    test('one wrong answer is never called weak', () {
      final singleFluke = item(mastery: 0.0, attempts: 1);

      expect(singleFluke.hasEnoughEvidence, isFalse);
      expect(singleFluke.isWeak, isFalse);
      expect(singleFluke.level, 'insufficient_data');
    });

    test('evidenced low mastery is weak and critical', () {
      final critical = item(mastery: 0.30, attempts: 5);

      expect(critical.hasEnoughEvidence, isTrue);
      expect(critical.isWeak, isTrue);
      expect(critical.isCritical, isTrue);
      expect(critical.level, 'critical');
    });

    test('incorrect counts non-correct attempts', () {
      final info = ConceptMastery(
        conceptId: 'c',
        lessonId: 'l',
        attempts: 4,
        correct: 3,
        mastery: 0.8,
        accuracy: 0.75,
        status: MasteryStatus.strong,
        lastAttemptAt: null,
      );

      expect(info.incorrect, 1);
    });
  });
}
