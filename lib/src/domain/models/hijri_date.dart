import '../enums/calendar_method.dart';

/// A Hijri (Islamic) calendar date with localized display fields and holidays.
class HijriDate {
  const HijriDate({
    required this.day,
    required this.month,
    required this.year,
    required this.weekdayEn,
    required this.weekdayAr,
    required this.monthEn,
    required this.monthAr,
    required this.monthLength,
    required this.method,
    this.holidays = const <String>[],
  });

  final int day;

  /// Month number 1..12 (1 = Muharram).
  final int month;
  final int year;

  /// English weekday name (transliterated), e.g. `"Al Juma'a"`.
  final String weekdayEn;

  /// Arabic weekday name, e.g. `"الجمعة"`.
  final String weekdayAr;

  /// English (transliterated) month name, e.g. `"Rajab"`.
  final String monthEn;

  /// Arabic month name, e.g. `"رَجَب"`.
  final String monthAr;

  /// Number of days in this Hijri month (29 or 30).
  final int monthLength;

  /// The calendar method used to compute this date.
  final CalendarMethod method;

  /// Islamic holidays/observances on this Hijri day (may be empty).
  final List<String> holidays;

  /// `dd-mm-yyyy`, matching the aladhan `hijri.date` field.
  String get formatted =>
      '${_two(day)}-${_two(month)}-${year.toString().padLeft(4, '0')}';

  static String _two(int n) => n < 10 ? '0$n' : '$n';
}
