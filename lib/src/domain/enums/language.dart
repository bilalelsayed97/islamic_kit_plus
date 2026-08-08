/// Supported localization languages for prayer, month and weekday names.
enum Language {
  /// English.
  en,

  /// Arabic.
  ar,
}

/// End-user localization (title + description) for [Language].
extension LanguageL10n on Language {
  /// Short UI label for [language].
  String title(Language language) => switch (this) {
        Language.en => language == Language.ar ? 'الإنجليزية' : 'English',
        Language.ar => language == Language.ar ? 'العربية' : 'Arabic',
      };

  /// One-sentence description for [language].
  String description(Language language) => switch (this) {
        Language.en => language == Language.ar
            ? 'عرض أسماء الصلوات والأشهر وأيام الأسبوع باللغة الإنجليزية.'
            : 'Display prayer, month and weekday names in English.',
        Language.ar => language == Language.ar
            ? 'عرض أسماء الصلوات والأشهر وأيام الأسبوع باللغة العربية.'
            : 'Display prayer, month and weekday names in Arabic.',
      };
}
