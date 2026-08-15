enum StudyTaskType {
  weakPoint,
  lesson,
  practice,
  review,
  exam,
}

class StudyTask {
  final String id;
  final StudyTaskType type;
  final String title;
  final String description;
  final String? lessonId;
  final String? conceptId;
  final int estimatedMinutes;

  /// Higher value = earlier in the plan. Deterministic priorities: weak
  /// points 100/90/70/50, lessons 50, daily practice 40, starter 30.
  final int priority;
  final bool completed;

  const StudyTask({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.lessonId,
    required this.conceptId,
    required this.estimatedMinutes,
    required this.priority,
    required this.completed,
  });

  StudyTask copyWith({bool? completed}) {
    return StudyTask(
      id: id,
      type: type,
      title: title,
      description: description,
      lessonId: lessonId,
      conceptId: conceptId,
      estimatedMinutes: estimatedMinutes,
      priority: priority,
      completed: completed ?? this.completed,
    );
  }
}

class StudyPlan {
  final DateTime date;
  final int availableMinutes;
  final List<StudyTask> tasks;

  const StudyPlan({
    required this.date,
    required this.availableMinutes,
    required this.tasks,
  });

  int get totalMinutes {
    return tasks.fold(
      0,
      (total, task) => total + task.estimatedMinutes,
    );
  }

  int get completedTasks {
    return tasks.where((task) => task.completed).length;
  }

  double get completionRatio {
    if (tasks.isEmpty) {
      return 0;
    }

    return completedTasks / tasks.length;
  }
}
