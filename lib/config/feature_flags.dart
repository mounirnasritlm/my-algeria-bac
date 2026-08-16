/// Product switches for incomplete or environment-specific features.
///
/// Keep defaults conservative and explicit. A flag should gate a complete
/// behavior boundary, not be used as a substitute for normal app state.
class FeatureFlags {
  const FeatureFlags._();

  static const bool remoteContentSync = true;
  static const bool studyPreferences = true;
  static const bool developerTools = false;
  static const bool onboarding = true;
}
