// Widget tests for the Weak Point Hunter screen: evidence-backed weak points,
// priority badges, and the empty state.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_algeria_bac/data/json_content_repository.dart';
import 'package:my_algeria_bac/data/progress_repository.dart';
import 'package:my_algeria_bac/models/weak_point.dart';
import 'package:my_algeria_bac/screens/weak_points_page.dart';

import 'helpers/demo_content_assets.dart';
import 'helpers/fake_asset_bundle.dart';

class _FakeProgressRepository extends ProgressRepository {
  _FakeProgressRepository(this.weakPoints);

  final List<WeakPoint> weakPoints;

  @override
  Future<List<WeakPoint>> getWeakPoints() async => weakPoints;
}

void main() {
  testWidgets('shows empty state when there is no evidence',
      (WidgetTester tester) async {
    final content = JsonContentRepository(
      assetBundle: FakeAssetBundle(demoContentAssets),
    );

    await tester.pumpWidget(
      _FakeProgressRepository(const []).build(
        contentRepository: content,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Not enough data yet'), findsOneWidget);
    expect(find.textContaining('at least 3 questions'), findsOneWidget);
  });

  testWidgets('lists evidenced weak points worst first with priority badges',
      (WidgetTester tester) async {
    final content = JsonContentRepository(
      assetBundle: FakeAssetBundle(demoContentAssets),
    );

    final weakPoints = _FakeProgressRepository(
      const [
        WeakPoint(
          conceptId: 'function_definition',
          lessonId: 'math_function_definition',
          mastery: 0.30,
          attempts: 5,
          priority: WeakPointPriority.critical,
        ),
        WeakPoint(
          conceptId: 'function_domain',
          lessonId: 'math_function_domain',
          mastery: 0.80,
          attempts: 4,
          priority: WeakPointPriority.low,
        ),
      ],
    );

    await tester.pumpWidget(weakPoints.build(contentRepository: content));
    await tester.pumpAndSettle();

    // Header count and description.
    expect(find.textContaining('2 concepts need'), findsOneWidget);
    expect(find.textContaining('at least 3 attempts'), findsOneWidget);

    // Human-readable concept names are resolved from the content repo.
    expect(find.text('Function definition'), findsOneWidget);

    // Priority badges for both evidenced concepts.
    expect(find.text('CRITICAL'), findsOneWidget);
    expect(find.text('LOW'), findsOneWidget);

    // Worst first: the critical concept is listed above the low one.
    final criticalY = tester.getTopLeft(find.text('Function definition')).dy;
    final lowY = tester.getTopLeft(find.text('Function domain')).dy;
    expect(criticalY, lessThan(lowY));

    // Mastery and attempts are shown per card.
    expect(find.text('30% mastery'), findsOneWidget);
    expect(find.text('5 attempts'), findsOneWidget);

    // Every card offers a train action.
    expect(find.text('Train this weakness'), findsNWidgets(2));
  });
}

extension on _FakeProgressRepository {
  Widget build({required JsonContentRepository contentRepository}) {
    return MaterialApp(
      home: WeakPointsPage(
        contentRepository: contentRepository,
        progressRepository: this,
      ),
    );
  }
}
