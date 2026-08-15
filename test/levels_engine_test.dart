// Level + BAC rank engine: thresholds, level floor/next, progress, and the
// rank ladder are all pure derivations from XP — nothing stores a level.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_algeria_bac/config/gamification_config.dart';
import 'package:my_algeria_bac/data/bac_ranks.dart';
import 'package:my_algeria_bac/data/levels_engine.dart';
import 'package:my_algeria_bac/models/bac_rank.dart';

void main() {
  group('levelFor', () {
    test('starts at level 1 below the first threshold', () {
      expect(levelFor(0), 1);
      expect(levelFor(99), 1);
    });

    test('crosses a level at every threshold', () {
      expect(levelFor(GamificationConfig.levelThresholds.first), 2);
      expect(levelFor(GamificationConfig.levelThresholds.last), 11);
      expect(levelFor(GamificationConfig.levelThresholds.last + 1), 11);
    });
  });

  group('levelFloor / nextLevelFloor', () {
    test('level 1 starts at 0 and needs the first threshold', () {
      expect(levelFloor(1), 0);
      expect(nextLevelFloor(1), GamificationConfig.levelThresholds.first);
    });

    test('a level sits between its floor and the next threshold', () {
      expect(levelFloor(3), GamificationConfig.levelThresholds[1]);
      expect(nextLevelFloor(3), GamificationConfig.levelThresholds[2]);
    });

    test('max level has a full progress bar', () {
      final maxLevel = levelFor(GamificationConfig.levelThresholds.last);
      expect(nextLevelFloor(maxLevel), levelFloor(maxLevel));
    });
  });

  group('levelInfoFor', () {
    test('produces a bounded level view', () {
      final info = levelInfoFor(300);

      expect(info.level, 3);
      expect(info.currentXp, 300);
      expect(info.xpForCurrentLevel, 250);
      expect(info.xpForNextLevel, 500);
      expect(info.remainingXp, 200);
      expect(info.progress, closeTo(50 / 250, 0.0001));
    });

    test('a fresh student is level 1 at 0% progress', () {
      final info = levelInfoFor(0);

      expect(info.level, 1);
      expect(info.currentXp, 0);
      expect(info.remainingXp, GamificationConfig.levelThresholds.first);
      expect(info.progress, 0);
    });

    test('progress clamps to 1 at max level', () {
      final info = levelInfoFor(GamificationConfig.levelThresholds.last + 500);
      expect(info.progress, 1);
      expect(info.remainingXp, 0);
    });
  });

  group('BAC ranks', () {
    test('ranks escalate with level', () {
      expect(rankForLevel(1).id, 'starter');
      expect(rankForLevel(3).id, 'learner');
      expect(rankForLevel(5).id, 'fighter');
      expect(rankForLevel(7).id, 'expert');
      expect(rankForLevel(10).id, 'crusher');
      expect(rankForLevel(50).id, 'crusher');
    });

    test('next rank is the first rank above the level', () {
      expect(nextRankForLevel(1)?.id, 'learner');
      expect(nextRankForLevel(9)?.id, 'crusher');
      expect(nextRankForLevel(10), isNull);
    });

    test('every rank is reachable and ordered', () {
      final levels = BacRanks.all.map((r) => r.minimumLevel).toList();
      for (var i = 1; i < levels.length; i++) {
        expect(levels[i], greaterThan(levels[i - 1]));
      }
    });
  });
}
