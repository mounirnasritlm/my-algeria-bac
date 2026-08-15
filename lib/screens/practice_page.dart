import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../models/exam.dart';
import 'exam_session_page.dart';

/// Practice tab: lists available BAC exams from the content repository.
class PracticePage extends StatefulWidget {
  final ContentRepository contentRepository;

  const PracticePage({super.key, required this.contentRepository});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  late Future<List<Exam>> _examsFuture;

  @override
  void initState() {
    super.initState();
    _examsFuture = widget.contentRepository.getExams();
  }

  Future<void> _refresh() async {
    final future = widget.contentRepository.getExams();
    setState(() {
      _examsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Exam>>(
        future: _examsFuture,
        builder: (context, snapshot) {
          final exams = snapshot.data;

          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (exams == null || exams.isEmpty) {
            return const Center(child: Text('No exams available yet.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Practice',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Take full BAC exams under timed conditions.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                for (final exam in exams)
                  _ExamCard(
                    exam: exam,
                    contentRepository: widget.contentRepository,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final Exam exam;
  final ContentRepository contentRepository;

  const _ExamCard({
    required this.exam,
    required this.contentRepository,
  });

  @override
  Widget build(BuildContext context) {
    final isDemo = exam.source.sourceType == 'demo_content';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(
            Icons.timer_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          exam.subjectId.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${exam.durationMinutes} min • ${exam.sections.length} '
          '${exam.sections.length == 1 ? 'section' : 'sections'}'
          '${isDemo ? ' • Demo' : ''}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExamSessionPage(
                contentRepository: contentRepository,
                examId: exam.id,
              ),
            ),
          );
        },
      ),
    );
  }
}
