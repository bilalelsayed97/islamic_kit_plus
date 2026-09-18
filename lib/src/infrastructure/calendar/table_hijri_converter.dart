import '../../domain/enums/calendar_method.dart';
import '../../domain/models/hijri_date.dart';
import '../../domain/ports/hijri_converter.dart';
import 'data/diyanet_table.dart';
import 'data/umm_al_qura_table.dart';
import 'hijri_date_builder.dart';
import 'julian_day_math.dart';

int _encode((int, int, int) ymd) => ymd.$1 * 10000 + ymd.$2 * 100 + ymd.$3;

/// Table-driven converter (Umm al-Qura, Diyanet). Both directions read the same
/// lunation table, so they are exact inverses: `toGregorian(fromGregorian(d))`
/// is `d` for every date in range.
///
/// (The PHP original converts Hijri -> Gregorian with the arithmetic calendar
/// instead, which lands a day or two off whenever the observed month start
/// differs from the tabular one. That is a defect, not a convention, and is
/// not reproduced here.)
///
/// `adjustment` shifts the result of [toGregorian] by whole days. It has no
/// effect on [fromGregorian], as in the original.
class TableHijriConverter implements HijriConverter {
  const TableHijriConverter({
    required this.method,
    required this.data,
    required this.lunations,
    required this.gregorianFrom,
    required this.gregorianTo,
    required this.hijriFrom,
    required this.hijriTo,
  });

  /// Umm al-Qura configuration (valid 1356–1500 AH).
  const TableHijriConverter.ummAlQura()
      : this(
          method: CalendarMethod.uaq,
          data: kUmmAlQuraTable,
          lunations: 16260,
          gregorianFrom: (1937, 3, 14),
          gregorianTo: (2077, 11, 16),
          hijriFrom: (1356, 1, 1),
          hijriTo: (1500, 12, 30),
        );

  /// Diyanet configuration (valid 1318–1449 AH).
  const TableHijriConverter.diyanet()
      : this(
          method: CalendarMethod.diyanet,
          data: kDiyanetTable,
          lunations: 15804,
          gregorianFrom: (1900, 5, 1),
          gregorianTo: (2028, 1, 26),
          hijriFrom: (1318, 1, 1),
          hijriTo: (1449, 8, 29),
        );

  @override
  final CalendarMethod method;
  final List<int> data;
  final int lunations;
  final (int, int, int) gregorianFrom;
  final (int, int, int) gregorianTo;
  final (int, int, int) hijriFrom;
  final (int, int, int) hijriTo;

  void verifyGregorian(DateTime date) {
    final v = _encode((date.year, date.month, date.day));
    if (v < _encode(gregorianFrom) || v > _encode(gregorianTo)) {
      throw ArgumentError(
        'Gregorian date out of range for ${method.code} '
        '($gregorianFrom .. $gregorianTo).',
      );
    }
  }

  void verifyHijri(int year, int month, int day) {
    final v = _encode((year, month, day));
    if (v < _encode(hijriFrom) || v > _encode(hijriTo)) {
      throw _hijriOutOfRange();
    }
  }

  ArgumentError _hijriOutOfRange() => ArgumentError(
        'Hijri date out of range for ${method.code} ($hijriFrom .. $hijriTo).',
      );

  @override
  HijriDate fromGregorian(DateTime date, {int adjustment = 0}) {
    verifyGregorian(date);
    final jd = JulianDayMath.gregorianToJd(date.year, date.month, date.day);
    final h = JulianDayMath.tableToHijri(data, lunations, jd);
    return buildHijriDate(
      day: h.day,
      month: h.month,
      year: h.year,
      monthLength: h.monthLength,
      gregorianWeekday: date.weekday,
      method: method,
    );
  }

  @override
  DateTime toGregorian(int year, int month, int day, {int adjustment = 0}) {
    verifyHijri(year, month, day);
    // A month number outside 1..12 can pass the bounds check above yet point
    // past the table.
    final jd = JulianDayMath.tableToJd(data, lunations, year, month, day);
    if (jd == null) throw _hijriOutOfRange();
    final g = JulianDayMath.jdToGregorian(jd + adjustment);
    return DateTime(g.year, g.month, g.day);
  }
}
