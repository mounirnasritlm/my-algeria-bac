import 'package:flutter/widgets.dart';

import '../app/app_scope.dart';
import 'app_language.dart';

/// Reads the selected language and rebuilds when the preference changes.
String appLanguageOf(BuildContext context) {
  return AppScope.maybeOf(context)?.languageCode ?? appLanguage;
}

/// Reads the selected language without registering an inherited dependency.
/// This is safe for async work started from `initState`.
String appLanguageWithoutListening(BuildContext context) {
  return AppScope.maybeOf(context, listen: false)?.languageCode ?? appLanguage;
}
