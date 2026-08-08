/// A Gregorian calendar date with localized display fields.
class GregorianDate {
  const GregorianDate({
    required this.day,
    required this.month,
    required this.year,
    required this.weekdayEn,
    required this.monthEn,
  });

  final int day;
  final int month;
  final int year;

  /// English weekday name, e.g. `"Wednesday"`.
  final String weekdayEn;

  /// English month name, e.g. `"January"`.
  final String monthEn;

  /// `dd-mm-yyyy`, matching the aladhan `gregorian.date` field.
  String get formatted =>
      '${_two(day)}-${_two(month)}-${year.toString().padLeft(4, '0')}';

  static String _two(int n) => n < 10 ? '0$n' : '$n';
}
