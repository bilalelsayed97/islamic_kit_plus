import '../domain/enums/calculation_method.dart';
import '../domain/enums/prayer.dart';
import '../domain/models/city.dart';
import '../domain/models/city_entry.dart';
import '../domain/models/next_prayer.dart';
import '../domain/models/prayer_result.dart';
import '../domain/models/qibla_direction.dart';
import '../domain/ports/geocoder.dart';
import '../domain/value_objects/calculation_parameters.dart';
import '../domain/value_objects/coordinates.dart';
import '../infrastructure/calendar/hijri_converter_factory.dart';
import '../infrastructure/config/bundled_method_map.dart';
import '../infrastructure/config/location_defaults.dart';
import '../infrastructure/geocoding/bundled_city_geocoder.dart';
import '../infrastructure/geocoding/city_directory.dart';
import 'prayer_calculator.dart';
import 'usecases/get_qibla.dart';

/// The library's top-level facade. Offers aladhan-equivalent operations —
/// timings, next prayer, calendars (Gregorian & Hijri, by coordinates / city /
/// address), qibla and the methods list — all computed offline.
class PrayerTimesService {
  PrayerTimesService({
    Geocoder? geocoder,
    this.directory,
    PrayerCalculator calculator = const PrayerCalculator(),
    QiblaCalculator qibla = const QiblaCalculator(),
    HijriConverterFactory hijriFactory = const HijriConverterFactory(),
  })  : geocoder = geocoder ?? BundledCityGeocoder(),
        _calculator = calculator,
        _qibla = qibla,
        _hijriFactory = hijriFactory;

  /// The geocoder used by the `*ByCity` / `*ByAddress` methods.
  final Geocoder geocoder;

  /// The bundled city database, used by the `*ByCoordinatesAuto` methods to
  /// resolve a GPS fix to a city, its timezone and its country's recommended
  /// calculation method.
  ///
  /// Optional: without it, coordinate-based automatic parameters fall back to
  /// [LocationDefaults] via the geocoder, which cannot resolve a country from
  /// coordinates — so pass one when you have the database open.
  final CityDirectory? directory;

  final PrayerCalculator _calculator;
  final QiblaCalculator _qibla;
  final HijriConverterFactory _hijriFactory;

  static const CalculationParameters _defaults = CalculationParameters();

  // ---------------------------------------------------------------------------
  // Daily timings
  // ---------------------------------------------------------------------------

  /// Prayer times for [date] at [coordinates].
  PrayerResult timings(
    DateTime date,
    Coordinates coordinates, [
    CalculationParameters params = _defaults,
  ]) =>
      _calculator.calculate(date, coordinates, params);

  /// Prayer times for [date] at a city, resolved via [geocoder].
  PrayerResult timingsByCity(
    String city, {
    required DateTime date,
    String? country,
    String? state,
    CalculationParameters params = _defaults,
  }) {
    final resolved = _requireCity(city, country: country, state: state);
    return _calculator.calculate(
        date, resolved.coordinates, _withCity(params, resolved));
  }

  /// Prayer times for [date] at a free-text address, resolved via [geocoder].
  PrayerResult timingsByAddress(
    String address, {
    required DateTime date,
    CalculationParameters params = _defaults,
  }) {
    final resolved = _requireCity(address);
    return _calculator.calculate(
        date, resolved.coordinates, _withCity(params, resolved));
  }

  // ---------------------------------------------------------------------------
  // Location-based defaults (automatic settings — no presets needed)
  // ---------------------------------------------------------------------------

  /// Recommended [CalculationParameters] for a country, choosing the method and
  /// Asr school by common regional convention (aladhan-style). Everything else
  /// keeps its default; override any field with `copyWith`.
  ///
  /// ```dart
  /// final p = service.recommendedParams('EG', utcOffset: Duration(hours: 2));
  /// service.timings(date, coords, p); // Egyptian method, automatically
  /// ```
  CalculationParameters recommendedParams(
    String countryCode, {
    Duration utcOffset = Duration.zero,
    String? timezoneName,
  }) =>
      CalculationParameters(
        method: LocationDefaults.methodForCountry(countryCode),
        school: LocationDefaults.schoolForCountry(countryCode),
        utcOffset: utcOffset,
        timezoneName: timezoneName,
      );

  /// Fully automatic prayer times for a city: the method and Asr school are
  /// chosen from the city's country, and the UTC offset comes from the city's
  /// stored (standard-time) offset. No [CalculationParameters] required.
  ///
  /// ```dart
  /// service.timingsByCityAuto('Cairo', country: 'EG', date: DateTime.now());
  /// ```
  PrayerResult timingsByCityAuto(
    String city, {
    required DateTime date,
    String? country,
    String? state,
  }) {
    final resolved = _requireCity(city, country: country, state: state);
    return _calculator.calculate(
      date,
      resolved.coordinates,
      _autoParams(resolved),
    );
  }

  /// [CalculationParameters] resolved automatically for a geocoded [city]
  /// (method + school by country, offset from the city).
  CalculationParameters autoParamsForCity(City city) => _autoParams(city);

  CalculationParameters _autoParams(City city) => CalculationParameters(
        method: LocationDefaults.methodForCountry(city.country),
        school: LocationDefaults.schoolForCountry(city.country),
        utcOffset: city.utcOffset,
      );

  /// [CalculationParameters] resolved automatically from a GPS fix.
  ///
  /// Requires [directory]. Finds the nearest city, then takes the calculation
  /// method from that city's country (as recorded in the bundled database),
  /// the Asr school from regional convention, and the UTC offset from the
  /// city's timezone.
  ///
  /// Returns `null` when no city can be resolved for the coordinates.
  ///
  /// ```dart
  /// final params = service.autoParamsForCoordinates(21.4225, 39.8262);
  /// // -> Umm al-Qura, standard Asr, UTC+3
  /// ```
  CalculationParameters? autoParamsForCoordinates(
    double latitude,
    double longitude,
  ) {
    final city = _requireDirectory().nearestCity(latitude, longitude);
    return city == null ? null : autoParamsForCityEntry(city);
  }

  /// [CalculationParameters] resolved automatically for a database [city] row.
  ///
  /// The method comes from the country's recorded preference, falling back to
  /// [LocationDefaults] when the database records none.
  CalculationParameters autoParamsForCityEntry(CityEntry city) {
    final method = city.calculationMethod ??
        LocationDefaults.methodForCountry(city.isoCode);
    return CalculationParameters(
      method: method,
      school: LocationDefaults.schoolForCountry(city.isoCode),
      utcOffset: city.utcOffset,
      timezoneName: city.timeZoneId,
    );
  }

  /// Fully automatic prayer times for a GPS fix: nearest city, its country's
  /// method, its timezone. No [CalculationParameters] required.
  ///
  /// Requires [directory]. Returns `null` when no city can be resolved.
  ///
  /// The stored offset is **standard time** — add an hour yourself where
  /// daylight saving is in force on [date].
  PrayerResult? timingsByCoordinatesAuto(
    double latitude,
    double longitude, {
    required DateTime date,
  }) {
    final city = _requireDirectory().nearestCity(latitude, longitude);
    if (city == null) return null;
    return _calculator.calculate(
      date,
      city.coordinates,
      autoParamsForCityEntry(city),
    );
  }

  CityDirectory _requireDirectory() {
    final open = directory;
    if (open == null) {
      throw StateError(
        'This operation needs the bundled city database. Construct '
        'PrayerTimesService with `directory:` (see CityDirectory.openFile, '
        'or loadBundledCityDirectory in islamic_kit_plus_flutter.dart).',
      );
    }
    return open;
  }

  // ---------------------------------------------------------------------------
  // Next prayer
  // ---------------------------------------------------------------------------

  /// The next obligatory prayer strictly after [from] (wall-clock local time,
  /// interpreted with `params.utcOffset`). Rolls to the next day's Fajr if
  /// [from] is after Isha.
  NextPrayer nextPrayer(
    DateTime from,
    Coordinates coordinates, [
    CalculationParameters params = _defaults,
  ]) {
    final localHour = from.hour + from.minute / 60 + from.second / 3600;
    final today = _calculator.calculate(
      DateTime(from.year, from.month, from.day),
      coordinates,
      params,
    );
    for (final prayer in Prayer.dailyObligatory) {
      final h = today.timings.raw[prayer];
      if (h != null && !h.isNaN && h > localHour) {
        return NextPrayer(
          prayer: prayer,
          time: today.timings.time(prayer),
          onDate: today.timings.date,
        );
      }
    }
    final tomorrow = DateTime(from.year, from.month, from.day + 1);
    final next = _calculator.calculate(tomorrow, coordinates, params);
    return NextPrayer(
      prayer: Prayer.fajr,
      time: next.timings.time(Prayer.fajr),
      onDate: tomorrow,
    );
  }

  /// [nextPrayer] resolved via [geocoder] for a free-text address.
  NextPrayer nextPrayerByAddress(
    String address,
    DateTime from, [
    CalculationParameters params = _defaults,
  ]) {
    final resolved = _requireCity(address);
    return nextPrayer(from, resolved.coordinates, _withCity(params, resolved));
  }

  // ---------------------------------------------------------------------------
  // Qibla & methods
  // ---------------------------------------------------------------------------

  /// The Qibla direction from [from] (degrees clockwise from true north).
  QiblaDirection qibla(Coordinates from) => _qibla.direction(from);

  /// All available calculation methods.
  List<CalculationMethod> methods() => CalculationMethod.values;

  // ---------------------------------------------------------------------------
  // Calendars — Gregorian
  // ---------------------------------------------------------------------------

  /// Every day of a Gregorian month.
  List<PrayerResult> monthlyCalendar(
    int year,
    int month,
    Coordinates coordinates, [
    CalculationParameters params = _defaults,
  ]) {
    final days = _daysInGregorianMonth(year, month);
    return <PrayerResult>[
      for (var d = 1; d <= days; d++)
        _calculator.calculate(DateTime(year, month, d), coordinates, params),
    ];
  }

  /// Every day of a Gregorian year, keyed by month 1..12.
  Map<int, List<PrayerResult>> annualCalendar(
    int year,
    Coordinates coordinates, [
    CalculationParameters params = _defaults,
  ]) =>
      <int, List<PrayerResult>>{
        for (var m = 1; m <= 12; m++)
          m: monthlyCalendar(year, m, coordinates, params),
      };

  /// Every day between [start] and [end] inclusive (max 11 months apart).
  List<PrayerResult> rangeCalendar(
    DateTime start,
    DateTime end,
    Coordinates coordinates, [
    CalculationParameters params = _defaults,
  ]) {
    final from = DateTime(start.year, start.month, start.day);
    final to = DateTime(end.year, end.month, end.day);
    if (to.isBefore(from)) {
      throw ArgumentError('end must be on or after start.');
    }
    final maxEnd = DateTime(start.year, start.month + 11, start.day);
    if (to.isAfter(maxEnd)) {
      throw ArgumentError('Date range must be at most 11 months.');
    }
    final out = <PrayerResult>[];
    for (var d = from;
        !d.isAfter(to);
        d = DateTime(d.year, d.month, d.day + 1)) {
      out.add(_calculator.calculate(d, coordinates, params));
    }
    return out;
  }

  /// [monthlyCalendar] for a city.
  List<PrayerResult> monthlyCalendarByCity(
    int year,
    int month,
    String city, {
    String? country,
    String? state,
    CalculationParameters params = _defaults,
  }) {
    final resolved = _requireCity(city, country: country, state: state);
    return monthlyCalendar(
        year, month, resolved.coordinates, _withCity(params, resolved));
  }

  // ---------------------------------------------------------------------------
  // Calendars — Hijri
  // ---------------------------------------------------------------------------

  /// Every day of a Hijri month.
  List<PrayerResult> monthlyHijriCalendar(
    int hijriYear,
    int hijriMonth,
    Coordinates coordinates, [
    CalculationParameters params = _defaults,
  ]) {
    final converter = _hijriFactory.create(params.calendarMethod);
    final start = converter.toGregorian(hijriYear, hijriMonth, 1);
    final length = converter.fromGregorian(start).monthLength;
    return <PrayerResult>[
      for (var i = 0; i < length; i++)
        _calculator.calculate(
          DateTime(start.year, start.month, start.day + i),
          coordinates,
          params,
        ),
    ];
  }

  /// Every day of a Hijri year, keyed by Hijri month 1..12.
  Map<int, List<PrayerResult>> annualHijriCalendar(
    int hijriYear,
    Coordinates coordinates, [
    CalculationParameters params = _defaults,
  ]) =>
      <int, List<PrayerResult>>{
        for (var m = 1; m <= 12; m++)
          m: monthlyHijriCalendar(hijriYear, m, coordinates, params),
      };

  /// [monthlyHijriCalendar] for a city.
  List<PrayerResult> monthlyHijriCalendarByCity(
    int hijriYear,
    int hijriMonth,
    String city, {
    String? country,
    String? state,
    CalculationParameters params = _defaults,
  }) {
    final resolved = _requireCity(city, country: country, state: state);
    return monthlyHijriCalendar(
      hijriYear,
      hijriMonth,
      resolved.coordinates,
      _withCity(params, resolved),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  City _requireCity(String query, {String? country, String? state}) {
    final city = geocoder.resolve(query, country: country, state: state);
    if (city == null) {
      throw StateError('Location not found: "$query".');
    }
    return city;
  }

  /// Applies the city's standard UTC offset unless the caller set one already.
  CalculationParameters _withCity(CalculationParameters params, City city) =>
      params.utcOffset == Duration.zero
          ? params.copyWith(utcOffset: city.utcOffset)
          : params;

  int _daysInGregorianMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;
}
