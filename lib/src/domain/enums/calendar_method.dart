import 'language.dart';

/// The Hijri calendar calculation method used for Gregorian <-> Hijri
/// conversion.
enum CalendarMethod {
  /// High Judicial Council of Saudi Arabia (Umm al-Qura table + announced
  /// lunar-sighting overrides). This is the aladhan.com default.
  hjcosa('HJCoSA'),

  /// Umm al-Qura (table lookup).
  uaq('UAQ'),

  /// Diyanet İşleri Başkanlığı (table lookup).
  diyanet('DIYANET'),

  /// Pure arithmetic (tabular) calendar; supports a day adjustment.
  mathematical('MATHEMATICAL');

  const CalendarMethod(this.code);

  /// The aladhan `calendarMethod` identifier.
  final String code;

  static CalendarMethod fromCode(String code) =>
      values.firstWhere((m) => m.code == code, orElse: () => hjcosa);
}

/// End-user localization (title + description) for [CalendarMethod].
extension CalendarMethodL10n on CalendarMethod {
  /// Short UI label for [language].
  String title(Language language) => switch (this) {
        CalendarMethod.hjcosa => language == Language.ar
            ? 'الهيئة العليا للقضاء'
            : 'High Judicial Council (KSA)',
        CalendarMethod.uaq =>
          language == Language.ar ? 'أم القرى' : 'Umm al-Qura',
        CalendarMethod.diyanet =>
          language == Language.ar ? 'ديانت التركية' : 'Diyanet (Turkey)',
        CalendarMethod.mathematical =>
          language == Language.ar ? 'حسابي' : 'Mathematical',
      };

  /// One-sentence description for [language].
  String description(Language language) => switch (this) {
        CalendarMethod.hjcosa => language == Language.ar
            ? 'تقويم أم القرى مع تعديلات الرؤية المعتمدة من الهيئة العليا للقضاء في السعودية (الإعداد الافتراضي).'
            : 'Umm al-Qura calendar with the Saudi High Judicial Council sighting adjustments (aladhan default).',
        CalendarMethod.uaq => language == Language.ar
            ? 'تقويم أم القرى الجدولي الرسمي في المملكة العربية السعودية.'
            : 'The official Umm al-Qura tabular calendar of Saudi Arabia.',
        CalendarMethod.diyanet => language == Language.ar
            ? 'التقويم الهجري الجدولي الصادر عن رئاسة الشؤون الدينية التركية (ديانت).'
            : "The tabular Hijri calendar published by Turkey's Diyanet İşleri Başkanlığı.",
        CalendarMethod.mathematical => language == Language.ar
            ? 'تقويم هجري حسابي (جدولي) بحت يدعم تعديل الأيام.'
            : 'A purely arithmetic (tabular) Hijri calendar that supports a day adjustment.',
      };
}
