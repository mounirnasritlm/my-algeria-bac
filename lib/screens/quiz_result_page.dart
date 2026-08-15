import 'package:flutter/material.dart';

class QuizResultPage extends StatelessWidget {
  final int totalQuestions;
  final int correctAnswers;

  const QuizResultPage({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
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

  String get title {
    if (accuracy >= 0.90) {
      return 'Excellent!';
    }

    if (accuracy >= 0.70) {
      return 'Great work!';
    }

    if (accuracy >= 0.50) {
      return 'Good start!';
    }

    return 'Keep practicing!';
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (accuracy * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz result'),
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
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),

                const SizedBox(height: 8),

                Text(
                  '$correctAnswers / $totalQuestions correct',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),

                const SizedBox(height: 28),

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
                          'Accuracy',
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
                              label: 'Correct',
                            ),
                            _ResultStat(
                              value:
                                  '${totalQuestions - correctAnswers}',
                              label: 'Wrong',
                            ),
                            _ResultStat(
                              value: '+$xpEarned',
                              label: 'XP',
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
                    child: const Text('Back to lesson'),
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
