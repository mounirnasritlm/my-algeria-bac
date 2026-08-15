import '../models/study_plan.dart';
import '../models/study_preferences.dart';
import '../models/user_progress.dart';
import '../models/weak_point.dart';
import 'content_repository.dart';
import 'progress_repository.dart';
import 'study_preferences_repository.dart';

/// Deterministic daily study planner.
///
/// No AI guessing: the plan is built from real inputs only — evidence-backed
/// weak points, unfinished lessons, and the student's available minutes.
/// Priority order: weak points > lessons > practice.
class StudyPlanRepository {
  final ContentRepository contentRepository;
  final ProgressRepository progressRepository;
  final StudyPreferencesRepository preferencesRepository;

  StudyPlanRepository({
    required this.contentRepository,
    ProgressRepository? progressRepository,
    StudyPreferencesRepository? preferencesRepository,
  })  : progressRepository = progressRepository ?? ProgressRepository(),
        preferencesRepository =
            preferencesRepository ?? StudyPreferencesRepository();

  Future<StudyPlan> generateTodayPlan() async {
    final preferences = await preferencesRepository.load();
    final weakPoints = await progressRepository.getWeakPoints();
    final lessonSubject = await _lessonSubjectMap();

    final tasks = <StudyTask>[];
    var remainingMinutes = preferences.dailyMinutes;

    // ------------------------------------------------
    // PRIORITY 1: Weak points (evidence-backed, worst first).
    // ------------------------------------------------
    if (preferences.includeWeakPoints) {
      for (final weakPoint in weakPoints) {
        if (remainingMinutes < 10) {
          break;
        }

        if (!_subjectAllowed(
          weakPoint.lessonId,
          lessonSubject,
          preferences,
        )) {
          continue;
        }

        final concept = await contentRepository.getConcept(weakPoint.conceptId);
        final minutes = remainingMinutes < 15 ? remainingMinutes : 15;

        tasks.add(
          StudyTask(
            id: 'weak_${weakPoint.conceptId}',
            type: StudyTaskType.weakPoint,
            title: 'Fix ${concept?.name ?? weakPoint.conceptId}',
            description: _weakPointDescription(weakPoint),
            lessonId: weakPoint.lessonId,
            conceptId: weakPoint.conceptId,
            estimatedMinutes: minutes,
            priority: _priorityValue(weakPoint.priority),
            completed: false,
          ),
        );

        remainingMinutes -= minutes;
      }
    }

    // ------------------------------------------------
    // PRIORITY 2: Unfinished lessons (per preferred subject).
    // ------------------------------------------------
    if (preferences.includeLessons && remainingMinutes >= 10) {
      final subjects = await contentRepository.getSubjects();

      for (final subject in subjects) {
        if (preferences.preferredSubjectIds.isNotEmpty &&
            !preferences.preferredSubjectIds.contains(subject.id)) {
          continue;
        }

        final lessons = await contentRepository.getLessonsForSubject(
          subject.id,
        );

        for (final lesson in lessons) {
          if (remainingMinutes < 10) {
            break;
          }

          final alreadyIncluded = tasks.any(
            (task) => task.lessonId == lesson.id,
          );
          if (alreadyIncluded) {
            continue;
          }

          if (await _lessonFinished(lesson.id)) {
            continue;
          }

          final baseMinutes = lesson.estimatedMinutes.clamp(10, 25);
          final minutes = remainingMinutes < baseMinutes
              ? remainingMinutes
              : baseMinutes;

          tasks.add(
            StudyTask(
              id: 'lesson_${lesson.id}',
              type: StudyTaskType.lesson,
              title: 'Study ${lesson.title}',
              description: lesson.description,
              lessonId: lesson.id,
              conceptId: null,
              estimatedMinutes: minutes,
              priority: 50,
              completed: false,
            ),
          );

          remainingMinutes -= minutes;
        }
      }
    }

    // ------------------------------------------------
    // PRIORITY 3: Daily practice.
    // ------------------------------------------------
    if (preferences.includePractice && remainingMinutes >= 10) {
      tasks.add(
        const StudyTask(
          id: 'daily_practice',
          type: StudyTaskType.practice,
          title: 'Quick Practice',
          description:
              'Answer a focused set of questions from today\'s topics.',
          lessonId: null,
          conceptId: null,
          estimatedMinutes: 10,
          priority: 40,
          completed: false,
        ),
      );
    }

    // Avoid creating an empty plan.
    if (tasks.isEmpty) {
      tasks.add(
        const StudyTask(
          id: 'starter_practice',
          type: StudyTaskType.practice,
          title: 'Start a practice session',
          description:
              'Begin with a short practice session to generate useful '
              'learning data.',
          lessonId: null,
          conceptId: null,
          estimatedMinutes: 10,
          priority: 30,
          completed: false,
        ),
      );
    }

    _sortByPriorityStable(tasks);

    return StudyPlan(
      date: DateTime.now(),
      availableMinutes: preferences.dailyMinutes,
      tasks: tasks,
    );
  }

  /// Sorts by priority (descending) while keeping insertion order for ties,
  /// because Dart's [List.sort] is not stable.
  void _sortByPriorityStable(List<StudyTask> tasks) {
    final indexed = <(int, StudyTask)>[
      for (var i = 0; i < tasks.length; i++) (i, tasks[i]),
    ];

    indexed.sort((a, b) {
      final byPriority = b.$2.priority.compareTo(a.$2.priority);
      if (byPriority != 0) {
        return byPriority;
      }
      return a.$1.compareTo(b.$1);
    });

    for (var i = 0; i < indexed.length; i++) {
      tasks[i] = indexed[i].$2;
    }
  }

  Future<Map<String, String>> _lessonSubjectMap() async {
    final map = <String, String>{};

    final subjects = await contentRepository.getSubjects();
    for (final subject in subjects) {
      final lessons = await contentRepository.getLessonsForSubject(subject.id);
      for (final lesson in lessons) {
        map[lesson.id] = subject.id;
      }
    }

    return map;
  }

  /// A lesson counts as finished once the recorded progress covers every
  /// question in the lesson. No progress means it is still unfinished.
  Future<bool> _lessonFinished(String lessonId) async {
    final progress = await progressRepository.getAllLessonProgress();

    LessonProgress? recorded;
    for (final item in progress) {
      if (item.id == lessonId) {
        recorded = item;
        break;
      }
    }

    if (recorded == null) {
      return false;
    }

    final totalQuestions =
        (await contentRepository.getQuestionsForLesson(lessonId)).length;
    if (totalQuestions == 0) {
      return false;
    }

    return recorded.questionsAnswered >= totalQuestions;
  }

  /// Weak-points resolve their subject through their lesson. When the lesson
  /// cannot be resolved, the weak point stays eligible (plan's documented
  /// behavior until the content graph carries subject ids on concepts).
  bool _subjectAllowed(
    String? lessonId,
    Map<String, String> lessonSubject,
    StudyPreferences preferences,
  ) {
    if (preferences.preferredSubjectIds.isEmpty) {
      return true;
    }

    if (lessonId == null) {
      return true;
    }

    final subjectId = lessonSubject[lessonId];
    if (subjectId == null) {
      return true;
    }

    return preferences.preferredSubjectIds.contains(subjectId);
  }

  int _priorityValue(WeakPointPriority priority) {
    switch (priority) {
      case WeakPointPriority.critical:
        return 100;
      case WeakPointPriority.high:
        return 90;
      case WeakPointPriority.medium:
        return 70;
      case WeakPointPriority.low:
        return 50;
    }
  }

  String _weakPointDescription(WeakPoint weakPoint) {
    final percentage = (weakPoint.mastery * 100).round();

    switch (weakPoint.priority) {
      case WeakPointPriority.critical:
        return '$percentage% mastery. This should be your top priority.';
      case WeakPointPriority.high:
        return '$percentage% mastery. More targeted practice is needed.';
      case WeakPointPriority.medium:
        return '$percentage% mastery. Keep developing this concept.';
      case WeakPointPriority.low:
        return '$percentage% mastery. A quick review will keep it fresh.';
    }
  }
}
