// Smart Study Plan screen: renders the plan header and task cards, opens a
// lesson from a weak point task, and links to the preferences screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_algeria_bac/data/content_repository.dart';
import 'package:my_algeria_bac/data/json_content_repository.dart';
import 'package:my_algeria_bac/data/study_plan_repository.dart';
import 'package:my_algeria_bac/models/study_plan.dart';
import 'package:my_algeria_bac/screens/study_plan_page.dart';

import 'helpers/demo_content_assets.dart';
import 'helpers/fake_asset_bundle.dart';

class _FakeStudyPlanRepository extends StudyPlanRepository {
  _FakeStudyPlanRepository(
    ContentRepository contentRepository, {
    required this.plan,
  }) : super(contentRepository: contentRepository);

  final StudyPlan plan;

  @override
  Future<StudyPlan> generateTodayPlan() async => plan;
}

void main() {
  late StudyPlanRepository fakeRepository;

  StudyPlan buildPlan() {
    return StudyPlan(
      date: DateTime(2026, 8, 15),
      availableMinutes: 60,
      tasks: [
        const StudyTask(
          id: 'math_function_definition_function_definition',
          type: StudyTaskType.weakPoint,
          title: 'Fix Function definition',
          description: 'Master the Function definition concept.',
          lessonId: 'math_function_definition',
          conceptId: 'function_definition',
          estimatedMinutes: 15,
          priority: 100,
          completed: false,
        ),
        const StudyTask(
          id: 'daily_practice',
          type: StudyTaskType.practice,
          title: 'Quick Practice',
          description: 'A 10-minute practice to keep your momentum.',
          lessonId: null,
          conceptId: null,
          estimatedMinutes: 10,
          priority: 40,
          completed: false,
        ),
      ],
    );
  }

  Widget buildPage() {
    return MaterialApp(
      home: StudyPlanPage(
        contentRepository: JsonContentRepository(
          assetBundle: FakeAssetBundle(demoContentAssets),
        ),
        planRepository: fakeRepository,
      ),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeRepository = _FakeStudyPlanRepository(
      JsonContentRepository(
        assetBundle: FakeAssetBundle(demoContentAssets),
      ),
      plan: buildPlan(),
    );
  });

  testWidgets('renders the plan header and task cards', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.text('🎯 SMART STUDY PLAN'), findsOneWidget);
    expect(find.text('0 / 2 tasks'), findsOneWidget);
    expect(find.text('60 minutes available today'), findsOneWidget);
    expect(find.text('Fix Function definition'), findsOneWidget);
    expect(find.text('15 min'), findsOneWidget);
    expect(find.text('Quick Practice'), findsOneWidget);
  });

  testWidgets('tapping a lesson task opens that lesson', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fix Function definition'));
    await tester.pumpAndSettle();

    expect(find.text('الرياضيات'), findsOneWidget);
  });

  testWidgets('tune button opens the preferences screen', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    expect(find.text('Study preferences'), findsOneWidget);
  });
}
