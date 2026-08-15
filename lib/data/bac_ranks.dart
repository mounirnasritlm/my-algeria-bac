/// 🇩🇿 BAC rank ladder. A motivational identity layer built on LEVEL, never on
/// academic score — XP says how much a student used the app, BAC marks say
/// how well they perform academically, and ranks are the in-between identity.
library;

import '../models/bac_rank.dart';

/// Highest rank the student qualifies for at [level].
BacRank rankForLevel(int level) {
  var current = BacRanks.all.first;

  for (final rank in BacRanks.all) {
    if (level >= rank.minimumLevel) {
      current = rank;
    }
  }

  return current;
}

/// The next rank above [level], when one exists.
BacRank? nextRankForLevel(int level) {
  for (final rank in BacRanks.all) {
    if (rank.minimumLevel > level) {
      return rank;
    }
  }

  return null;
}
