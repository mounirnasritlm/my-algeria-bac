// Deterministic Smart Study Plan tests: priorities, budgets, unfinished
// lesson detection, subject filtering, and the fallback starter task.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_algeria_bac/data/content_repository.dart';
import 'package:my_algeria_bac/data/json_content_repository.dart';
import 'package:my_algeria_bac/data/progress_repository.dart';
import 'package:my_algeria_bac/data/study_plan_repository.dart';
import 'package:my_algeria_bac/data/study_preferences_repository.dart';
import 'package:my_algeria_bac/models/study_plan.dart';
import 'package:my_algeria_bac/models/study_preferences.dart';
import 'package:my_algeria_bac/models/user_progress.dart';
import 'package:my_algeria_bac/models/weak_point.dart';

import 'helpers/demo_content_assets.dart';
import 'helpers/fake_asset_bundle.dart';

class _FakeProgressRepository extends ProgressRepository {
  _FakeProgressRepository({
    List<WeakPoint>? weakPoints,
    List<LessonProgress>? lessonProgress,
  })  : weakPoints = weakPoints ?? const [],
        lessonProgress = lessonProgress ?? const [];

  final List<WeakPoint> weakPoints;
  final List<LessonProgress> lessonProgress;

  @override
  Future<List<WeakPoint>> getWeakPoints() async => weakPoints;

  @override
  Future<List<LessonProgress>> getAllLessonProgress() async => lessonProgress;
}

class _FakePreferencesRepository extends StudyPreferencesRepository {
  _FakePreferencesRepository(this.preferences);

  StudyPreferences preferences;

  @override
  Future<StudyPreferences> load() async => preferences;

  @override
  Future<void> save(StudyPreferences preferences) async {
    this.preferences = preferences;
  }
}

void main() {
  ContentRepository content() {
    return JsonContentRepository(
      assetBundle: FakeAssetBundle(demoContentAssets),
    );
  }

  WeakPoint weakPoint({
    required String conceptId,
    required String lessonId,
    required double mastery,
    WeakPointPriority priority = WeakPointPriority.critical,
  }) {
    return WeakPoint(
      conceptId: conceptId,
      lessonId: lessonId,
      mastery: mastery,
      attempts: 5,
      priority: priority,
    );
  }

  StudyPlanRepository planner({
    required ContentRepository contentRepository,
    required _FakeProgressRepository progress,
    required _FakePreferencesRepository preferences,
  }) {
    return StudyPlanRepository(
      contentRepository: contentRepository,
      progressRepository: progress,
      preferencesRepository: preferences,
      languageCode: 'en',
    );
  }

  test('weak points come first with human-readable concept names', () async {
    final repository = planner(
      contentRepository: content(),
      progress: _FakeProgressRepository(
        weakPoints: [
          weakPoint(
            conceptId: 'function_definition',
            lessonId: 'math_function_definition',
            mastery: 0.30,
            priority: WeakPointPriority.critical,
          ),
          weakPoint(
            conceptId: 'function_domain',
            lessonId: 'math_function_domain',
            mastery: 0.80,
            priority: WeakPointPriority.low,
          ),
        ],
      ),
      preferences: _FakePreferencesRepository(
        const StudyPreferences(
          dailyMinutes: 60,
          preferredSubjectIds: [],
          includeWeakPoints: true,
          includeLessons: false,
          includePractice: false,
        ),
      ),
    );

    final plan = await repository.generateTodayPlan();

    expect(plan.tasks.map((t) => t.title), [
      'Fix Function definition',
      'Fix Function domain',
    ]);
    expect(plan.tasks.first.type, StudyTaskType.weakPoint);
    expect(plan.tasks.first.priority, greaterThan(plan.tasks.last.priority));
    expect(plan.tasks.first.lessonId, 'math_function_definition');
    expect(plan.tasks.first.conceptId, 'function_definition');
  });

  test('only unfinished lessons are added, within the available budget',
      () async {
    final now = DateTime.now();

    final repository = planner(
      contentRepository: content(),
      progress: _FakeProgressRepository(
        lessonProgress: [
          // math_function_definition has 2 questions and is fully answered
          // => finished.
          LessonProgress(
            id: 'math_function_definition',
            title: 'Function concept',
            questionsAnswered: 2,
            questionsCorrect: 1,
            xpEarned: 20,
            accuracy: 0.5,
            updatedAt: now,
          ),
        ],
      ),
      preferences: _FakePreferencesRepository(
        const StudyPreferences(
          dailyMinutes: 45,
          preferredSubjectIds: [],
          includeWeakPoints: false,
          includeLessons: true,
          includePractice: false,
        ),
      ),
    );

    final plan = await repository.generateTodayPlan();

    final lessonIds = plan.tasks
        .where((t) => t.type == StudyTaskType.lesson)
        .map((t) => t.lessonId)
        .toList();

    expect(lessonIds, contains('math_derivative_definition'));
    expect(lessonIds, contains('physics_motion_basics'));
    expect(lessonIds, isNot(contains('math_function_definition')));
    expect(plan.totalMinutes, lessThanOrEqualTo(plan.availableMinutes));
  });

  test('preferred subjects restrict which lessons are scheduled', () async {
    final repository = planner(
      contentRepository: content(),
      progress: _FakeProgressRepository(),
      preferences: _FakePreferencesRepository(
        const StudyPreferences(
          dailyMinutes: 120,
          preferredSubjectIds: ['physics'],
          includeWeakPoints: false,
          includeLessons: true,
          includePractice: false,
        ),
      ),
    );

    final plan = await repository.generateTodayPlan();

    final lessonIds = plan.tasks.map((t) => t.lessonId).toList();
    expect(lessonIds, ['physics_motion_basics']);
  });

  test('weak points respect preferred subjects through their lesson',
      () async {
    final repository = planner(
      contentRepository: content(),
      progress: _FakeProgressRepository(
        weakPoints: [
          weakPoint(
            conceptId: 'function_definition',
            lessonId: 'math_function_definition',
            mastery: 0.20,
            priority: WeakPointPriority.critical,
          ),
          weakPoint(
            conceptId: 'motion_basics',
            lessonId: 'physics_motion_basics',
            mastery: 0.35,
            priority: WeakPointPriority.high,
          ),
        ],
      ),
      preferences: _FakePreferencesRepository(
        const StudyPreferences(
          dailyMinutes: 60,
          preferredSubjectIds: ['physics'],
          includeWeakPoints: true,
          includeLessons: false,
          includePractice: false,
        ),
      ),
    );

    final plan = await repository.generateTodayPlan();

    expect(plan.tasks.map((t) => t.title), ['Fix Motion']);
  });

  test('practice task is added when minutes remain', () async {
    final repository = planner(
      contentRepository: content(),
      progress: _FakeProgressRepository(),
      preferences: _FakePreferencesRepository(
        const StudyPreferences(
          dailyMinutes: 30,
          preferredSubjectIds: [],
          includeWeakPoints: false,
          includeLessons: false,
          includePractice: true,
        ),
      ),
    );

    final plan = await repository.generateTodayPlan();

    expect(plan.tasks.single.type, StudyTaskType.practice);
    expect(plan.tasks.single.id, 'daily_practice');
    expect(plan.tasks.single.estimatedMinutes, 10);
  });

  test('an empty plan falls back to a starter practice task', () async {
    final repository = planner(
      contentRepository: content(),
      progress: _FakeProgressRepository(),
      preferences: _FakePreferencesRepository(
        const StudyPreferences(
          dailyMinutes: 30,
          preferredSubjectIds: [],
          includeWeakPoints: false,
          includeLessons: false,
          includePractice: false,
        ),
      ),
    );

    final plan = await repository.generateTodayPlan();

    expect(plan.tasks.single.id, 'starter_practice');
    expect(plan.tasks.single.title, 'Start a practice session');
  });

  test('plan never schedules more minutes than available', () async {
    final repository = planner(
      contentRepository: content(),
      progress: _FakeProgressRepository(
        weakPoints: [
          weakPoint(
            conceptId: 'function_definition',
            lessonId: 'math_function_definition',
            mastery: 0.10,
            priority: WeakPointPriority.critical,
          ),
        ],
      ),
      preferences: _FakePreferencesRepository(
        const StudyPreferences(
          dailyMinutes: 45,
          preferredSubjectIds: [],
          includeWeakPoints: true,
          includeLessons: true,
          includePractice: true,
        ),
      ),
    );

    final plan = await repository.generateTodayPlan();

    expect(plan.totalMinutes, lessThanOrEqualTo(plan.availableMinutes));
    expect(plan.tasks.isNotEmpty, isTrue);
  });

  test('same-priority weak points keep their weakest-first order', () async {
    final repository = planner(
      contentRepository: content(),
      progress: _FakeProgressRepository(
        weakPoints: [
          weakPoint(
            conceptId: 'function_definition',
            lessonId: 'math_function_definition',
            mastery: 0.60,
            priority: WeakPointPriority.medium,
          ),
          weakPoint(
            conceptId: 'function_domain',
            lessonId: 'math_function_domain',
            mastery: 0.65,
            priority: WeakPointPriority.medium,
          ),
        ],
      ),
      preferences: _FakePreferencesRepository(
        const StudyPreferences(
          dailyMinutes: 60,
          preferredSubjectIds: [],
          includeWeakPoints: true,
          includeLessons: false,
          includePractice: false,
        ),
      ),
    );

    final plan = await repository.generateTodayPlan();

    expect(plan.tasks.map((t) => t.title), [
      'Fix Function definition',
      'Fix Function domain',
    ]);
  });
}
