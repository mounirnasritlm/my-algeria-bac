import 'package:flutter/material.dart';

import '../config/app_language_context.dart';
import '../l10n/app_strings.dart';
import '../models/achievement.dart';
import '../services/gamification_service.dart';

class QuizResultPage extends StatelessWidget {
  final int totalQuestions;
  final int correctAnswers;

  /// Achievement/level outcome of the finished quiz, when one was computed.
  final GamificationResult? gamification;

  const QuizResultPage({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
    this.gamification,
  });

  double get accuracy {
    if (totalQuestions == 0) {
      return 0;
    }

    return correctAnswers / totalQuestions;
  }

  int get xpEarned {
    return correctAnswers * 10;
  }

  String title(BuildContext context) {
    if (accuracy >= 0.90) {
      return AppStrings.t(context, 'result_excellent');
    }

    if (accuracy >= 0.70) {
      return AppStrings.t(context, 'result_great_work');
    }

    if (accuracy >= 0.50) {
      return AppStrings.t(context, 'result_good_start');
    }

    return AppStrings.t(context, 'result_keep_practicing');
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (accuracy * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t(context, 'quiz_result')),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    size: 55,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  title(context),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),

                const SizedBox(height: 8),

                Text(
                  AppStrings.t(context, 'correct_of_total',
                      args: [correctAnswers, totalQuestions]),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),

                const SizedBox(height: 28),

                if (gamification != null)
                  _GamificationSummary(result: gamification!),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.t(context, 'accuracy'),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceAround,
                          children: [
                            _ResultStat(
                              value: '$correctAnswers',
                              label: AppStrings.t(context, 'correct'),
                            ),
                            _ResultStat(
                              value:
                                  '${totalQuestions - correctAnswers}',
                              label: AppStrings.t(context, 'wrong'),
                            ),
                            _ResultStat(
                              value: '+$xpEarned',
                              label: AppStrings.t(context, 'xp'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(AppStrings.t(context, 'back_to_lesson')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GamificationSummary extends StatelessWidget {
  final GamificationResult result;

  const _GamificationSummary({required this.result});

  @override
  Widget build(BuildContext context) {
    final levelUp = result.levelUp;

    return Column(
      children: [
        if (levelUp != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 34)),
                const SizedBox(height: 6),
                Text(
                  AppStrings.t(context, 'level_up'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.t(context, 'level_x_to_y',
                      args: [levelUp.oldLevel, levelUp.newLevel]),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (result.hasNewAchievements) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.t(context, 'achievement_unlocked'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final achievement in result.newAchievements)
                    _AchievementRow(achievement: achievement),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _AchievementRow extends StatelessWidget {
  final Achievement achievement;

  const _AchievementRow({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final languageCode = appLanguageOf(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(achievement.icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.titleForLanguage(languageCode),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  achievement.descriptionForLanguage(languageCode),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${achievement.xpReward}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String value;
  final String label;

  const _ResultStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
