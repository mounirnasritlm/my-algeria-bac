import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_algeria_bac/data/student_profile_repository.dart';
import 'package:my_algeria_bac/models/student_profile.dart';

void main() {
  test('profile is absent until all onboarding choices are saved', () async {
    SharedPreferences.setMockInitialValues({});

    final repository = StudentProfileRepository();
    expect(await repository.load(), isNull);

    const profile = StudentProfile(
      stream: BacStream.mathematics,
      bacYear: 2027,
      targetAverage: 16.5,
      languageCode: 'fr',
      dailyGoalMinutes: 60,
    );
    await repository.save(profile);

    final loaded = await repository.load();
    expect(loaded?.stream, BacStream.mathematics);
    expect(loaded?.bacYear, 2027);
    expect(loaded?.targetAverage, 16.5);
    expect(loaded?.languageCode, 'fr');
    expect(loaded?.dailyGoalMinutes, 60);
  });
}
