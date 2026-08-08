import 'language.dart';

/// Output format for a computed time.
enum TimeFormat {
  /// 24-hour clock, e.g. `03:57`.
  h24('24h'),

  /// 12-hour clock with am/pm suffix, e.g. `3:57 am`.
  h12('12h'),

  /// 12-hour clock without a suffix, e.g. `3:57`.
  h12NoSuffix('12hNS'),

  /// Raw floating-point hours (0..24), e.g. `3.95`.
  float('Float'),

  /// ISO-8601 with timezone offset, e.g. `2014-04-24T03:57:00+01:00`.
  iso8601('iso8601');

  const TimeFormat(this.code);

  /// The aladhan format identifier.
  final String code;
}

/// End-user localization (title + description) for [TimeFormat].
extension TimeFormatL10n on TimeFormat {
  /// Short UI label for [language].
  String title(Language language) => switch (this) {
        TimeFormat.h24 => language == Language.ar ? '24 ساعة' : '24-Hour',
        TimeFormat.h12 => language == Language.ar ? '12 ساعة' : '12-Hour',
        TimeFormat.h12NoSuffix => language == Language.ar
            ? '12 ساعة بدون لاحقة'
            : '12-Hour (No Suffix)',
        TimeFormat.float =>
          language == Language.ar ? 'ساعات عشرية' : 'Decimal Hours',
        TimeFormat.iso8601 =>
          language == Language.ar ? 'آيزو 8601' : 'ISO 8601',
      };

  /// One-sentence description for [language].
  String description(Language language) => switch (this) {
        TimeFormat.h24 => language == Language.ar
            ? 'نظام 24 ساعة، مثل 03:57.'
            : '24-hour clock, e.g. 03:57.',
        TimeFormat.h12 => language == Language.ar
            ? 'نظام 12 ساعة مع لاحقة ص/م، مثل 3:57 ص.'
            : '12-hour clock with an am/pm suffix, e.g. 3:57 am.',
        TimeFormat.h12NoSuffix => language == Language.ar
            ? 'نظام 12 ساعة بدون لاحقة ص/م، مثل 3:57.'
            : '12-hour clock without an am/pm suffix, e.g. 3:57.',
        TimeFormat.float => language == Language.ar
            ? 'ساعات عشرية خام من 0 إلى 24، مثل 3.95.'
            : 'Raw floating-point hours from 0 to 24, e.g. 3.95.',
        TimeFormat.iso8601 => language == Language.ar
            ? 'طابع زمني بصيغة آيزو 8601 مع إزاحة المنطقة الزمنية، مثل 2014-04-24T03:57:00+01:00.'
            : 'ISO-8601 timestamp with a timezone offset, e.g. 2014-04-24T03:57:00+01:00.',
      };
}
