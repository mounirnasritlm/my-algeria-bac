import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../models/lesson.dart';
import '../models/subject.dart';
import 'lesson_page.dart';

class SubjectPage extends StatelessWidget {
  final ContentRepository contentRepository;
  final String subjectId;

  const SubjectPage({
    super.key,
    required this.contentRepository,
    required this.subjectId,
  });

  @override
  Widget build(BuildContext context) {
    final future = () async {
      final subject = await contentRepository.getSubject(subjectId);
      final lessons = await contentRepository.getLessonsForSubject(subjectId);
      return (subject: subject, lessons: lessons);
    }();

    return Scaffold(
      appBar: AppBar(
        title: Text(subjectId),
      ),
      body: FutureBuilder<({Subject? subject, List<Lesson> lessons})>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final subject = snapshot.data?.subject;
          final lessons = snapshot.data?.lessons ?? const <Lesson>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                subject?.name ?? subjectId,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Learning path',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete the lessons in order and practice what you learn.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 20),

              for (int index = 0; index < lessons.length; index++)
                _LessonCard(
                  lesson: lessons[index],
                  number: index + 1,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LessonPage(
                          contentRepository: contentRepository,
                          lessonId: lessons[index].id,
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final int number;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lesson,
    required this.number,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      lesson.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 15,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${lesson.estimatedMinutes} min',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.layers_outlined,
                          size: 15,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${lesson.conceptIds.length} concepts',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
