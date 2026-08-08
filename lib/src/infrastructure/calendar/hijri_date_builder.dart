import '../../domain/enums/calendar_method.dart';
import '../../domain/models/hijri_date.dart';
import '../localization/localizer.dart';
import 'data/hijri_holidays.dart';

/// Assembles a fully-populated [HijriDate] from raw numeric parts, filling in
/// localized month/weekday names (from [Localizer]) and holidays. The weekday is
/// derived from the corresponding Gregorian date's ISO weekday.
HijriDate buildHijriDate({
  required int day,
  required int month,
  required int year,
  required int monthLength,
  required int gregorianWeekday,
  required CalendarMethod method,
}) {
  final m = Localizer.islamicMonths[month]!;
  final wd = Localizer.hijriWeekday(gregorianWeekday);
  final holidays = kHijriHolidays[month]?[day] ?? const <String>[];
  return HijriDate(
    day: day,
    month: month,
    year: year,
    weekdayEn: wd.en,
    weekdayAr: wd.ar,
    monthEn: m.en,
    monthAr: m.ar,
    monthLength: monthLength,
    method: method,
    holidays: holidays,
  );
}
