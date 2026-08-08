import 'language.dart';

/// How the Midnight (and the night thirds) are anchored.
enum MidnightMode {
  /// Midpoint of Sunset to Sunrise.
  standard(0, 'STANDARD'),

  /// Midpoint of Sunset to Fajr (Shia / Jafari).
  jafari(1, 'JAFARI');

  const MidnightMode(this.aladhanId, this.metaValue);

  /// Integer value accepted by the aladhan `midnightMode` query parameter.
  final int aladhanId;

  /// String value echoed in the aladhan `meta.midnightMode` field.
  final String metaValue;

  static MidnightMode fromAladhanId(int id) =>
      values.firstWhere((m) => m.aladhanId == id, orElse: () => standard);
}

/// End-user localization (title + description) for [MidnightMode].
extension MidnightModeL10n on MidnightMode {
  /// Short UI label for [language].
  String title(Language language) => switch (this) {
        MidnightMode.standard =>
          language == Language.ar ? 'القياسي' : 'Standard',
        MidnightMode.jafari =>
          language == Language.ar ? 'الجعفري (الشيعة)' : 'Jafari (Shia)',
      };

  /// One-sentence description for [language].
  String description(Language language) => switch (this) {
        MidnightMode.standard => language == Language.ar
            ? 'منتصف الليل هو منتصف المدة بين الغروب وشروق اليوم التالي.'
            : 'Midnight is the midpoint between sunset and the following sunrise.',
        MidnightMode.jafari => language == Language.ar
            ? 'منتصف الليل هو منتصف المدة بين الغروب وفجر اليوم التالي.'
            : 'Midnight is the midpoint between sunset and the following Fajr.',
      };
}
