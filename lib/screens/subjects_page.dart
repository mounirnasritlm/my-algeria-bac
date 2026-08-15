import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../models/subject.dart';
import 'subject_page.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({
    super.key,
    required this.contentRepository,
  });

  final ContentRepository contentRepository;

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  late final Future<List<Subject>> _subjects =
      widget.contentRepository.getSubjects();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Learn',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a subject to start learning.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),

          FutureBuilder<List<Subject>>(
            future: _subjects,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final subjects = snapshot.data ?? const <Subject>[];

              return Column(
                children: [
                  for (final subject in subjects)
                    _SubjectCard(
                      subject: subject,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SubjectPage(
                              contentRepository: widget.contentRepository,
                              subjectId: subject.id,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.subject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  subject.icon,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${subject.lessonIds.length} lessons',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
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
