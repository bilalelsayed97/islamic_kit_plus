import '../../domain/enums/high_latitude_rule.dart';
import '../../domain/enums/midnight_mode.dart';
import '../../domain/enums/prayer.dart';
import '../../domain/ports/twilight_strategy.dart';
import '../../domain/value_objects/calculation_parameters.dart';
import '../../domain/value_objects/coordinates.dart';
import '../../domain/value_objects/method_params.dart';
import 'solar_time.dart';

/// Seconds in a day. The engine works in whole seconds from 00:00 UTC of the
/// requested civil date, which keeps every interval exact.
const int _secondsPerDay = 86400;

/// Computes raw prayer times (fractional local hours) for a date and location.
///
/// Values may be negative or exceed 24 when an event rolls into the adjacent
/// day; `null` marks a time that cannot be computed (polar day or polar
/// night).
///
/// Times are rounded to the nearest minute here, so a formatted result never
/// depends on formatting-time rounding.
class AstronomicalCalculator {
  const AstronomicalCalculator();

  /// Returns raw fractional local hours for every [Prayer].
  ///
  /// [twilight] supplies the Moonsighting Committee's seasonal bounds; it is
  /// required only when `params.method.usesMoonsighting` is set.
  ///
  /// [ramadan] selects the method's Ramadan Isha interval where it defines one
  /// (Umm al-Qura lengthens 90 minutes to 120). The caller decides, because
  /// resolving the Hijri month is a calendar concern, not an astronomical one.
  Map<Prayer, double?> compute(
    DateTime date,
    Coordinates coordinates,
    CalculationParameters params, {
    TwilightStrategy? twilight,
    bool ramadan = false,
  }) {
    return _Computation(date, coordinates, params, twilight, ramadan).run();
  }
}

class _Computation {
  _Computation(
    this.date,
    this.coordinates,
    this.params,
    this.twilight,
    this.ramadan,
  );

  final DateTime date;
  final Coordinates coordinates;
  final CalculationParameters params;
  final TwilightStrategy? twilight;
  final bool ramadan;

  late final MethodParams _mp =
      ramadan ? params.effectiveParams.forRamadan() : params.effectiveParams;

  double get _latitude => coordinates.latitude;

  Map<Prayer, double?> run() {
    final solar = SolarTime(
      year: date.year,
      month: date.month,
      day: date.day,
      coordinates: coordinates,
      elevation: params.elevation,
    );

    final transit = _seconds(solar.transit);
    final sunrise = _seconds(solar.sunrise);
    final sunset = _seconds(solar.sunset);
    final asr = _seconds(solar.afternoon(params.resolvedShadowFactor));

    // Polar day or polar night: the sun never crosses the horizon, so no time
    // can be anchored and the whole day is invalid.
    if (transit == null || sunrise == null || sunset == null || asr == null) {
      return <Prayer, double?>{for (final p in Prayer.values) p: null};
    }

    final night = (sunrise + _secondsPerDay) - sunset;
    final fajr = _fajr(solar, sunrise: sunrise, night: night);
    final maghrib = _maghribBase(solar, sunset: sunset);
    final isha = _isha(solar, sunset: sunset, maghrib: maghrib, night: night);

    final imsak = fajr == null ? null : fajr - params.imsakMinutes * 60;
    final dhuhr = transit + params.dhuhrMinutes * 60;

    final adjustments = _mp.adjustments;
    final result = <Prayer, int?>{
      Prayer.imsak: imsak,
      Prayer.fajr: _shift(fajr, adjustments.fajr),
      Prayer.sunrise: _shift(sunrise, adjustments.sunrise),
      Prayer.dhuhr: _shift(dhuhr, adjustments.dhuhr),
      Prayer.asr: _shift(asr, adjustments.asr),
      Prayer.sunset: sunset,
      Prayer.maghrib: _shift(maghrib, adjustments.maghrib),
      Prayer.isha: _shift(isha, adjustments.isha),
    };

    // Midnight and the night thirds are derived from the *unadjusted* anchors.
    result.addAll(_nightTimes(sunset: sunset, sunrise: sunrise, fajr: fajr));

    return _finalize(result);
  }

  // ---------------------------------------------------------------------------
  // Individual times
  // ---------------------------------------------------------------------------

  /// Fajr, floored by the high-latitude safe bound.
  int? _fajr(SolarTime solar, {required int sunrise, required int night}) {
    var candidate = _seconds(
      solar.hourAngle(-_mp.fajrAngle, afterTransit: false),
    );

    // Above 55°N the Moonsighting method abandons the angle entirely.
    if (_usesMoonsighting && _latitude >= 55) {
      candidate = sunrise - night ~/ 7;
    }

    final rule = params.resolvedHighLatitudeRule;
    if (rule == HighLatitudeRule.none) return candidate;

    final safe = _usesMoonsighting
        ? sunrise - _twilight.fajrSecondsBeforeSunrise(date, _latitude)
        : sunrise - (night * _nightPortion(rule, _mp.fajrAngle)).truncate();

    if (candidate == null || candidate < safe) return safe;
    return candidate;
  }

  /// The Maghrib anchor: sunset, or the method's own interval/angle.
  int _maghribBase(SolarTime solar, {required int sunset}) {
    final minutes = _mp.maghribMinutesAfterSunset;
    if (minutes != null) return sunset + minutes * 60;

    final angle = _mp.maghribAngle;
    if (angle != null) {
      final byAngle = _seconds(solar.hourAngle(-angle, afterTransit: true));
      if (byAngle != null) return byAngle;
    }
    return sunset;
  }

  /// Isha, capped by the high-latitude safe bound when angle-based.
  int? _isha(
    SolarTime solar, {
    required int sunset,
    required int maghrib,
    required int night,
  }) {
    // A fixed interval is definitional: no high-latitude bound applies.
    final interval = _mp.ishaMinutesAfterMaghrib;
    if (interval != null) return maghrib + interval * 60;

    final ishaAngle = _mp.ishaAngle ?? 0;
    var candidate = _seconds(solar.hourAngle(-ishaAngle, afterTransit: true));

    if (_usesMoonsighting && _latitude >= 55) {
      candidate = sunset + night ~/ 7;
    }

    final rule = params.resolvedHighLatitudeRule;
    if (rule == HighLatitudeRule.none) return candidate;

    final safe = _usesMoonsighting
        ? sunset +
            _twilight.ishaSecondsAfterSunset(date, _latitude, params.shafaq)
        : sunset + (night * _nightPortion(rule, ishaAngle)).truncate();

    if (candidate != null && candidate <= safe) return candidate;
    return safe;
  }

  /// Midnight and the night thirds.
  ///
  /// The night runs from sunset to the following Fajr
  /// ([MidnightMode.jafari], the default) or to the following sunrise
  /// ([MidnightMode.standard]).
  Map<Prayer, int?> _nightTimes({
    required int sunset,
    required int sunrise,
    required int? fajr,
  }) {
    final anchor =
        params.resolvedMidnightMode == MidnightMode.standard ? sunrise : fajr;
    if (anchor == null) {
      return <Prayer, int?>{
        Prayer.midnight: null,
        Prayer.firstThird: null,
        Prayer.lastThird: null,
      };
    }

    final night = (anchor + _secondsPerDay) - sunset;
    return <Prayer, int?>{
      Prayer.midnight: sunset + night ~/ 2,
      Prayer.firstThird: sunset + night ~/ 3,
      Prayer.lastThird: sunset + (night * 2) ~/ 3,
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool get _usesMoonsighting => params.method.usesMoonsighting;

  /// The Moonsighting strategy. Only read when the method needs it, so a
  /// caller that never selects Moonsighting need not supply one.
  TwilightStrategy get _twilight {
    final strategy = twilight;
    if (strategy == null) {
      throw StateError(
        'The ${params.method.code} method needs a TwilightStrategy. '
        'Pass one to AstronomicalCalculator.compute().',
      );
    }
    return strategy;
  }

  /// The fraction of the night that bounds a twilight time under [rule].
  double _nightPortion(HighLatitudeRule rule, double angle) {
    switch (rule) {
      case HighLatitudeRule.angleBased:
        return angle / 60.0;
      case HighLatitudeRule.oneSeventh:
        return 1 / 7;
      case HighLatitudeRule.middleOfNight:
      case HighLatitudeRule.none:
        return 1 / 2;
    }
  }

  /// Truncates fractional UTC hours to whole seconds, or `null` when the value
  /// is not a real time (the sun never reached the requested angle).
  int? _seconds(double hours) {
    if (hours.isNaN || hours.isInfinite) return null;
    return (hours * 3600).floor();
  }

  int? _shift(int? seconds, int minutes) =>
      seconds == null ? null : seconds + minutes * 60;

  /// Applies user tuning, rounds to the nearest minute and converts to
  /// fractional local hours.
  Map<Prayer, double?> _finalize(Map<Prayer, int?> times) {
    final tune = params.tune.toMap();
    final offsetSeconds = params.utcOffset.inSeconds;

    return <Prayer, double?>{
      for (final entry in times.entries)
        entry.key: _toLocalHours(
          entry.value,
          tune[entry.key] ?? 0,
          offsetSeconds,
        ),
    };
  }

  double? _toLocalHours(int? seconds, int tuneMinutes, int offsetSeconds) {
    if (seconds == null) return null;
    final tuned = seconds + tuneMinutes * 60;
    // Round to the nearest minute: seconds >= 30 advance the minute.
    final minutes = (tuned / 60).floor() + (tuned % 60 >= 30 ? 1 : 0);
    return (minutes * 60 + offsetSeconds) / 3600.0;
  }
}
