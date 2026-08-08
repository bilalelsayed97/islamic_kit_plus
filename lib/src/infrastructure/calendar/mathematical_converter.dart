import '../../domain/enums/calendar_method.dart';
import '../../domain/models/hijri_date.dart';
import '../../domain/ports/hijri_converter.dart';
import 'hijri_date_builder.dart';
import 'julian_day_math.dart';

/// Pure arithmetic (tabular) Hijri calendar. No validity restrictions; supports
/// a whole-day [adjustment] in both directions. Faithful port of the PHP
/// `Mathematical\Calculator`. Month length is always reported as 30 (the
/// algorithm does not track true month lengths).
class MathematicalConverter implements HijriConverter {
  const MathematicalConverter();

  @override
  CalendarMethod get method => CalendarMethod.mathematical;

  @override
  HijriDate fromGregorian(DateTime date, {int adjustment = 0}) {
    final jd = JulianDayMath.gregorianToJd(date.year, date.month, date.day);
    final h = JulianDayMath.mathematicalToHijri(jd, adjustment);
    return buildHijriDate(
      day: h.day,
      month: h.month,
      year: h.year,
      monthLength: 30,
      gregorianWeekday: date.weekday,
      method: CalendarMethod.mathematical,
    );
  }

  @override
  DateTime toGregorian(int year, int month, int day, {int adjustment = 0}) {
    final jd = JulianDayMath.hijriToJd(year, month, day, adjust: adjustment);
    final g = JulianDayMath.jdToGregorian(jd);
    return DateTime(g.year, g.month, g.day);
  }
}
