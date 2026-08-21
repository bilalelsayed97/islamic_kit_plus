import '../domain/models/calculation_meta.dart';
import '../domain/models/date_info.dart';
import '../domain/models/gregorian_date.dart';
import '../domain/models/prayer_result.dart';
import '../domain/models/prayer_time.dart';
import '../domain/ports/twilight_strategy.dart';
import '../domain/value_objects/calculation_parameters.dart';
import '../domain/value_objects/coordinates.dart';
import '../infrastructure/astronomy/astronomical_calculator.dart';
import '../infrastructure/calendar/hijri_converter_factory.dart';
import '../infrastructure/calendar/table_hijri_converter.dart';
import '../infrastructure/localization/localizer.dart';
import '../infrastructure/twilight/moonsighting_twilight.dart';

/// Hijri month number of Ramadan.
const int _ramadanMonth = 9;

String _two(int n) => n < 10 ? '0$n' : '$n';

/// Builds a complete [PrayerResult] (timings + date block + meta) for one date
/// and location. Composes the astronomy engine, the Hijri converter and the
/// localizer — the single use case the facade builds every feature on.
class PrayerCalculator {
  const PrayerCalculator({
    this.astronomy = const AstronomicalCalculator(),
    this.hijriFactory = const HijriConverterFactory(),
    this.moonsighting = const MoonsightingTwilight(),
  });

  final AstronomicalCalculator astronomy;
  final HijriConverterFactory hijriFactory;
  final TwilightStrategy moonsighting;

  PrayerResult calculate(
    DateTime date,
    Coordinates coordinates,
    CalculationParameters params,
  ) {
    final twilight = params.method.usesMoonsighting ? moonsighting : null;
    final raw = astronomy.compute(
      date,
      coordinates,
      params,
      twilight: twilight,
      ramadan: _isRamadan(date, params),
    );
    final civil = DateTime(date.year, date.month, date.day);

    return PrayerResult(
      timings:
          PrayerTimings(raw: raw, date: civil, utcOffset: params.utcOffset),
      date: _dateInfo(date, params),
      meta: _meta(coordinates, params),
    );
  }

  /// Whether [date] falls in Ramadan, for methods whose Isha interval changes
  /// during the month (only Umm al-Qura does).
  ///
  /// Always resolved against the Umm al-Qura table regardless of the caller's
  /// `calendarMethod`, because the rule itself is Saudi. Dates outside the
  /// table's range fall back to the method's ordinary interval.
  bool _isRamadan(DateTime date, CalculationParameters params) {
    if (!params.effectiveParams.hasRamadanIshaInterval) return false;
    const converter = TableHijriConverter.ummAlQura();
    try {
      return converter.fromGregorian(date).month == _ramadanMonth;
    } on ArgumentError {
      return false;
    }
  }

  DateInfo _dateInfo(DateTime date, CalculationParameters params) {
    final gregorian = GregorianDate(
      day: date.day,
      month: date.month,
      year: date.year,
      weekdayEn: Localizer.gregorianWeekday(date.weekday).en,
      monthEn: Localizer.gregorianMonths[date.month]!.en,
    );
    final hijri =
        hijriFactory.create(params.calendarMethod).fromGregorian(date);
    final readable =
        '${_two(date.day)} ${Localizer.monthAbbrEn[date.month - 1]} ${date.year}';
    final midnightUtc = DateTime.utc(date.year, date.month, date.day);
    final timestamp =
        midnightUtc.millisecondsSinceEpoch ~/ 1000 - params.utcOffset.inSeconds;

    return DateInfo(
      readable: readable,
      timestamp: timestamp,
      gregorian: gregorian,
      hijri: hijri,
    );
  }

  CalculationMeta _meta(Coordinates coordinates, CalculationParameters params) {
    return CalculationMeta(
      coordinates: coordinates,
      timezone: params.timezoneName ?? _utcLabel(params.utcOffset),
      method: params.method,
      methodParams: params.effectiveParams,
      school: params.school,
      midnightMode: params.resolvedMidnightMode,
      latitudeAdjustmentMethod: params.resolvedHighLatitudeRule,
      shafaq: params.shafaq,
      offsets: params.tune.toMap(),
    );
  }

  String _utcLabel(Duration offset) {
    if (offset == Duration.zero) return 'UTC';
    final sign = offset.isNegative ? '-' : '+';
    final abs = offset.abs();
    return 'UTC$sign${_two(abs.inHours)}:${_two(abs.inMinutes % 60)}';
  }
}
