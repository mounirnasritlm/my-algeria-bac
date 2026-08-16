/// The default display language of the app.
///
/// All content models store localized strings keyed by language code; the UI
/// reads them through this constant. 'ar' is the primary language; models fall
/// back to 'fr' then 'en' when a key is missing.
const String appLanguage = 'ar';

const supportedAppLanguages = <String>['fr', 'ar', 'en'];

String normalizeAppLanguage(String? value) {
  return supportedAppLanguages.contains(value) ? value! : appLanguage;
}
