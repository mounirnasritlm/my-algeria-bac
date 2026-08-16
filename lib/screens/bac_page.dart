import 'package:flutter/material.dart';

import '../config/app_language_context.dart';
import '../data/content_repository.dart';
import '../data/exam_session_repository.dart';
import '../data/progress_repository.dart';
import '../l10n/app_strings.dart';
import '../models/exam.dart';
import 'exam_session_page.dart';

/// BAC Arena: the picker for full mock papers. Each entry launches the BAC
/// Boss timed session for that exam.
class BacPage extends StatefulWidget {
  final ContentRepository contentRepository;

  /// Injectable for tests; forwarded to the exam session page.
  final ProgressRepository? progressRepository;

  final ExamSessionRepository? sessionRepository;

  const BacPage({
    super.key,
    required this.contentRepository,
    this.progressRepository,
    this.sessionRepository,
  });

  @override
  State<BacPage> createState() => _BacPageState();
}

class _BacPageState extends State<BacPage> {
  late Future<List<_ExamTile>> _examsFuture;
  String? _languageCode;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = appLanguageOf(context);
    if (_languageCode == languageCode) {
      return;
    }

    _languageCode = languageCode;
    _examsFuture = _loadTiles();
  }

  Future<List<_ExamTile>> _loadTiles() async {
    final languageCode =
        _languageCode ?? appLanguageWithoutListening(context);
    final exams = await widget.contentRepository.getExams();

    final tiles = <_ExamTile>[];
    for (final exam in exams) {
      final subject =
          await widget.contentRepository.getSubject(exam.subjectId);
      tiles.add(
        _ExamTile(
          exam: exam,
          subjectName: subject?.nameForLanguage(languageCode),
        ),
      );
    }

    return tiles;
  }

  int _questionCount(Exam exam) {
    return exam.sections.fold(0, (sum, section) {
      return sum + section.questionIds.length;
    });
  }

  void _openExam(Exam exam) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExamSessionPage(
          contentRepository: widget.contentRepository,
          examId: exam.id,
          progressRepository: widget.progressRepository,
          sessionRepository: widget.sessionRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t(context, 'bac_arena'))),
      body: FutureBuilder<List<_ExamTile>>(
        future: _examsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(AppStrings.t(context, 'could_not_load_exams')));
          }

          final tiles = snapshot.data ?? const <_ExamTile>[];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF111827), Color(0xFF374151)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚔️ BAC BOSS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No shortcuts. No hints. Train like it is exam day.',
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Available exams',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 12),
              if (tiles.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No exams available yet.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              else
                for (final tile in tiles) ...[
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const CircleAvatar(
                        child: Icon(Icons.assignment_outlined),
                      ),
                      title: Text(
                        tile.subjectName ?? tile.exam.subjectId,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        '${_questionCount(tile.exam)} questions • '
                        '${tile.exam.durationMinutes} min',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openExam(tile.exam),
                    ),
                  ),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _ExamTile {
  final Exam exam;
  final String? subjectName;

  const _ExamTile({required this.exam, required this.subjectName});
}
