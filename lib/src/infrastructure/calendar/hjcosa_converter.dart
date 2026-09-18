import '../../domain/enums/calendar_method.dart';
import '../../domain/models/hijri_date.dart';
import '../../domain/ports/hijri_converter.dart';
import 'data/hijri_sightings.dart';
import 'data/umm_al_qura_table.dart';
import 'hijri_date_builder.dart';
import 'julian_day_math.dart';
import 'table_hijri_converter.dart';

String _two(int n) => n < 10 ? '0$n' : '$n';

/// High Judiciary Council of Saudi Arabia: the Umm al-Qura table overlaid with
/// announced lunar-sighting adjustments (both directions). Faithful port of the
/// PHP `HighJudiciaryCouncilOfSaudiArabia` class.
class HjcosaConverter implements HijriConverter {
  HjcosaConverter()
      : _reverse = <String, String>{
          for (final e in kHjcosaSightings.entries) e.value: e.key,
        };

  static const TableHijriConverter _uaq = TableHijriConverter(
    method: CalendarMethod.hjcosa,
    data: kUmmAlQuraTable,
    lunations: 16260,
    gregorianFrom: (1937, 3, 14),
    gregorianTo: (2077, 11, 16),
    hijriFrom: (1356, 1, 1),
    hijriTo: (1500, 12, 30),
  );

  /// Announced Hijri `dd-mm-yyyy` -> Gregorian `dd-mm-yyyy`.
  final Map<String, String> _reverse;

  @override
  CalendarMethod get method => CalendarMethod.hjcosa;

  @override
  HijriDate fromGregorian(DateTime date, {int adjustment = 0}) {
    _uaq.verifyGregorian(date);
    final key = '${_two(date.day)}-${_two(date.month)}-${date.year}';
    final announced = kHjcosaSightings[key];
    if (announced == null) return _uaq.fromGregorian(date);

    final parts = announced.split('-');
    final d = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final y = int.parse(parts[2]);

    // Month length from a reference calc on the 7th of the announced month,
    // since sightings adjust the *start* of a month.
    final refJd = JulianDayMath.hijriToJd(y, m, 7);
    final ref = JulianDayMath.tableToHijri(kUmmAlQuraTable, 16260, refJd);

    return buildHijriDate(
      day: d,
      month: m,
      year: y,
      monthLength: ref.monthLength,
      gregorianWeekday: date.weekday,
      method: CalendarMethod.hjcosa,
    );
  }

  @override
  DateTime toGregorian(int year, int month, int day, {int adjustment = 0}) {
    _uaq.verifyHijri(year, month, day);
    final key = '${_two(day)}-${_two(month)}-$year';
    final gregorian = _reverse[key];
    if (gregorian != null) {
      final p = gregorian.split('-');
      return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    }
    // No announcement for this date: the Umm al-Qura table, the same one
    // fromGregorian falls back to.
    return _uaq.toGregorian(year, month, day, adjustment: adjustment);
  }
}
