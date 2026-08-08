import 'language.dart';

/// Juristic school that determines the shadow ratio used for Asr.
enum AsrSchool {
  /// Shafi'i, Maliki, Hanbali — Asr begins at shadow factor 1.
  standard(0, 'STANDARD', 1),

  /// Hanafi — Asr begins at shadow factor 2.
  hanafi(1, 'HANAFI', 2);

  const AsrSchool(this.aladhanId, this.metaValue, this.shadowFactor);

  /// Integer value accepted by the aladhan `school` query parameter.
  final int aladhanId;

  /// String value echoed in the aladhan `meta.school` field.
  final String metaValue;

  /// The Asr shadow-length multiplier.
  final int shadowFactor;

  static AsrSchool fromAladhanId(int id) =>
      values.firstWhere((s) => s.aladhanId == id, orElse: () => standard);
}

/// End-user localization (title + description) for [AsrSchool].
extension AsrSchoolL10n on AsrSchool {
  /// Short UI label for [language].
  String title(Language language) => switch (this) {
        AsrSchool.standard => language == Language.ar
            ? "القياسي (الشافعي والمالكي والحنبلي)"
            : "Standard (Shafi'i, Maliki, Hanbali)",
        AsrSchool.hanafi => language == Language.ar ? 'الحنفي' : 'Hanafi',
      };

  /// One-sentence description for [language].
  String description(Language language) => switch (this) {
        AsrSchool.standard => language == Language.ar
            ? 'يبدأ وقت العصر عندما يساوي طول ظل الشيء طوله (معامل الظل 1).'
            : "Asr begins when an object's shadow equals its own length (shadow factor 1).",
        AsrSchool.hanafi => language == Language.ar
            ? 'يبدأ وقت العصر عندما يبلغ طول ظل الشيء ضعف طوله (معامل الظل 2).'
            : "Asr begins when an object's shadow is twice its own length (shadow factor 2).",
      };
}
