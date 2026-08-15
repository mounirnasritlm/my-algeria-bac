import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../models/concept.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import '../models/subject.dart';
import 'quiz_page.dart';

class LessonPage extends StatefulWidget {
  final ContentRepository contentRepository;
  final String lessonId;

  const LessonPage({
    super.key,
    required this.contentRepository,
    required this.lessonId,
  });

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  late final Future<_LessonData> _future = _load();

  Future<_LessonData> _load() async {
    final lesson = await widget.contentRepository.getLesson(widget.lessonId);
    if (lesson == null) {
      return const _LessonData(
        lesson: null,
        subject: null,
        concepts: [],
        questions: [],
      );
    }

    final subject =
        await widget.contentRepository.getSubject(lesson.subjectId);
    final concepts =
        await widget.contentRepository.getConceptsForLesson(widget.lessonId);
    final questions =
        await widget.contentRepository.getQuestionsForLesson(widget.lessonId);

    return _LessonData(
      lesson: lesson,
      subject: subject,
      concepts: concepts,
      questions: questions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LessonData>(
      future: _future,
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: Text(snapshot.data?.subject?.name ?? 'Lesson'),
          ),
          body: _buildBody(snapshot),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<_LessonData> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }

    final lesson = snapshot.data?.lesson;
    final questions = snapshot.data?.questions ?? const <Question>[];

    if (lesson == null) {
      return const Center(child: Text('Lesson not found.'));
    }

    final concepts = snapshot.data!.concepts;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'LESSON',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lesson.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            lesson.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 24),

          _InfoCard(
            icon: Icons.schedule_outlined,
            title: 'Estimated time',
            value: '${lesson.estimatedMinutes} minutes',
          ),

          const SizedBox(height: 12),

          _InfoCard(
            icon: Icons.lightbulb_outline,
            title: 'Concepts',
            value: '${lesson.conceptIds.length} concepts',
          ),

          const SizedBox(height: 24),

          const _DemoContentWarning(),

          const SizedBox(height: 24),

          Text(
            'Lesson content',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),

          const SizedBox(height: 12),

          _LessonContentCard(concepts: concepts),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: questions.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QuizPage(
                            contentRepository: widget.contentRepository,
                            lessonId: lesson.id,
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.play_arrow),
              label: Text(
                questions.isEmpty
                    ? 'Quiz unavailable'
                    : 'Start quiz (${questions.length})',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonData {
  const _LessonData({
    required this.lesson,
    required this.subject,
    required this.concepts,
    required this.questions,
  });

  final Lesson? lesson;
  final Subject? subject;
  final List<Concept> concepts;
  final List<Question> questions;
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoContentWarning extends StatelessWidget {
  const _DemoContentWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.35),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.amber,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This is demonstration content only. '
              'It is not official BAC material.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonContentCard extends StatelessWidget {
  final List<Concept> concepts;

  const _LessonContentCard({
    required this.concepts,
  });

  @override
  Widget build(BuildContext context) {
    final bullets = concepts.isEmpty
        ? const [
            'Understand the core idea.',
            'Recognize the important concepts.',
            'Practice with questions.',
          ]
        : [
            for (final concept in concepts) concept.name,
          ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What you will learn',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            for (final bullet in bullets) _Bullet(text: bullet),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•  ',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}
