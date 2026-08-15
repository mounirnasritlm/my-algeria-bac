class UserProgress {
  final List<LessonProgress> lessons;

  final int currentStreak;

  final int longestStreak;

  const UserProgress({
    required this.lessons,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory UserProgress.empty() {
    return const UserProgress(
      lessons: [],
      currentStreak: 0,
      longestStreak: 0,
    );
  }

  factory UserProgress.fromLessons({
    required List<LessonProgress> lessons,
  }) {
    final dates = <DateTime>{
      for (final lesson in lessons) _dayOf(lesson.updatedAt),
    }.toList()
      ..sort();

    int longestStreak = 0;
    int run = 0;
    DateTime? previous;

    for (final date in dates) {
      if (previous != null && _daysBetween(previous, date) == 1) {
        run++;
      } else {
        run = 1;
      }

      if (run > longestStreak) {
        longestStreak = run;
      }

      previous = date;
    }

    final today = _dayOf(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    final lastDate = dates.isEmpty ? null : dates.last;

    int currentStreak = 0;

    if (lastDate != null) {
      if (lastDate == today || lastDate == yesterday) {
        currentStreak = run;
      }
    }

    return UserProgress(
      lessons: lessons,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }

  UserProgress copyWithProgress({
    required String lessonId,
    required String title,
    required int questionsAnswered,
    required int questionsCorrect,
    required int xpEarned,
  }) {
    final byId = <String, LessonProgress>{
      for (final lesson in lessons) lesson.id: lesson,
    };

    final previous = byId[lessonId];

    final merged = LessonProgress(
      id: lessonId,
      title: title,
      questionsAnswered: questionsAnswered,
      questionsCorrect: questionsCorrect,
      xpEarned: (previous?.xpEarned ?? 0) + xpEarned,
      accuracy: questionsAnswered == 0
          ? 0
          : questionsCorrect / questionsAnswered,
      updatedAt: DateTime.now(),
    );

    byId[lessonId] = merged;

    return UserProgress.fromLessons(
      lessons: byId.values.toList(),
    );
  }

  static DateTime _dayOf(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static int _daysBetween(DateTime a, DateTime b) {
    return b.difference(a).inDays.abs();
  }
}

class LessonProgress {
  final String id;

  final String title;

  final int questionsAnswered;

  final int questionsCorrect;

  final int xpEarned;

  final double accuracy;

  final DateTime updatedAt;

  const LessonProgress({
    required this.id,
    required this.title,
    required this.questionsAnswered,
    required this.questionsCorrect,
    required this.xpEarned,
    required this.accuracy,
    required this.updatedAt,
  });
}
