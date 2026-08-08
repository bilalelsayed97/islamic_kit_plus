import 'language.dart';

/// Adjustment applied to Fajr/Isha/Imsak/Maghrib at high latitudes where the
/// sun may not reach the required twilight angle.
enum HighLatitudeRule {
  /// No adjustment.
  none(0, 'NONE'),

  /// The night is split in half (middle of the night).
  middleOfNight(1, 'MIDDLE_OF_THE_NIGHT'),

  /// One-seventh of the night.
  oneSeventh(2, 'ONE_SEVENTH'),

  /// A portion of the night proportional to the twilight angle (angle / 60).
  angleBased(3, 'ANGLE_BASED');

  const HighLatitudeRule(this.aladhanId, this.metaValue);

  /// Integer value accepted by the aladhan `latitudeAdjustmentMethod` parameter.
  /// (`none` has no aladhan integer; it is represented as `0` here.)
  final int aladhanId;

  /// String value echoed in the aladhan `meta.latitudeAdjustmentMethod` field.
  final String metaValue;

  static HighLatitudeRule fromAladhanId(int id) =>
      values.firstWhere((r) => r.aladhanId == id, orElse: () => angleBased);
}

/// End-user localization (title + description) for [HighLatitudeRule].
extension HighLatitudeRuleL10n on HighLatitudeRule {
  /// Short UI label for [language].
  String title(Language language) => switch (this) {
        HighLatitudeRule.none => language == Language.ar ? 'بدون' : 'None',
        HighLatitudeRule.middleOfNight =>
          language == Language.ar ? 'منتصف الليل' : 'Middle of Night',
        HighLatitudeRule.oneSeventh =>
          language == Language.ar ? 'سُبع الليل' : 'One-Seventh',
        HighLatitudeRule.angleBased =>
          language == Language.ar ? 'حسب الزاوية' : 'Angle-Based',
      };

  /// One-sentence description for [language].
  String description(Language language) => switch (this) {
        HighLatitudeRule.none => language == Language.ar
            ? 'لا يُطبَّق أي تعديل على المواقيت في خطوط العرض العالية.'
            : 'No high-latitude adjustment is applied to the twilight times.',
        HighLatitudeRule.middleOfNight => language == Language.ar
            ? 'يُقسَّم الليل نصفين ليقيّد وقتي الفجر والعشاء عند منتصف الليل.'
            : 'The night is split in half to bound the Fajr and Isha times at its midpoint.',
        HighLatitudeRule.oneSeventh => language == Language.ar
            ? 'يُقسَّم الليل إلى سبعة أجزاء لضبط وقتي الفجر والعشاء.'
            : 'The night is divided into seven parts to bound the Fajr and Isha times.',
        HighLatitudeRule.angleBased => language == Language.ar
            ? 'يُستخدم جزء من الليل يتناسب مع زاوية الشفق (الزاوية ÷ 60).'
            : 'A portion of the night proportional to the twilight angle (angle / 60) is used.',
      };
}
