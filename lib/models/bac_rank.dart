/// A BAC rank: a motivational identity tier granted by LEVEL (see
/// `data/bac_ranks.dart`). Ranks are intentionally separate from academic
/// performance — a rank is earned by effort, not by exam marks.
class BacRank {
  final String id;
  final String title;
  final String subtitle;

  /// Lowest level that grants this rank.
  final int minimumLevel;

  const BacRank({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.minimumLevel,
  });
}

class BacRanks {
  const BacRanks._();

  static const List<BacRank> all = [
    BacRank(
      id: 'starter',
      title: 'Nouveau Candidat',
      subtitle: 'بداية المشوار',
      minimumLevel: 1,
    ),
    BacRank(
      id: 'learner',
      title: 'Candidat Sérieux',
      subtitle: 'راك بديت صح',
      minimumLevel: 3,
    ),
    BacRank(
      id: 'fighter',
      title: 'Bac Fighter',
      subtitle: 'ما نستسلموش',
      minimumLevel: 5,
    ),
    BacRank(
      id: 'expert',
      title: 'Candidat Solide',
      subtitle: 'المستوى طالع',
      minimumLevel: 7,
    ),
    BacRank(
      id: 'crusher',
      title: 'Bac Crusher',
      subtitle: 'راك داخل بقوة',
      minimumLevel: 10,
    ),
  ];
}
