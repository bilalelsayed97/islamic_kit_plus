import 'dart:math' as math;

import '../../domain/enums/high_latitude_rule.dart';
import '../../domain/enums/midnight_mode.dart';
import '../../domain/enums/prayer.dart';
import '../../domain/ports/twilight_strategy.dart';
import '../../domain/value_objects/calculation_parameters.dart';
import '../../domain/value_objects/coordinates.dart';
import '../../domain/value_objects/method_params.dart';
import 'degree_math.dart';
import 'julian_date.dart';
import 'sun_position.dart';

/// Computes raw prayer times (fractional local hours) for a date and location.
///
/// Faithful port of the PHP `PrayerTimes` computation pipeline (PrayTimes.js
/// v2.3). Values may be negative or exceed 24 when an event rolls into the
/// adjacent day; `NaN` marks an uncomputable time.
class AstronomicalCalculator {
  const AstronomicalCalculator();

  /// Returns the raw fractional-hours for every [Prayer].
  ///
  /// [twilight] (e.g. Moonsighting) overrides Fajr/Imsak/Isha after the base
  /// computation, when provided.
  Map<Prayer, double?> compute(
    DateTime date,
    Coordinates coordinates,
    CalculationParameters params, {
    TwilightStrategy? twilight,
  }) {
    return _Computation(date, coordinates, params, twilight).run();
  }
}

class _Computation {
  _Computation(this.date, this.coordinates, this.params, this.twilight);

  final DateTime date;
  final Coordinates coordinates;
  final CalculationParameters params;
  final TwilightStrategy? twilight;

  double get _lat => coordinates.latitude;
  double get _lng => coordinates.longitude;
  MethodParams get _mp => params.effectiveParams;

  double get _ishaAngle =>
      _mp.ishaAngle ?? _mp.ishaMinutesAfterMaghrib?.toDouble() ?? 0;
  double get _maghribAngle =>
      _mp.maghribAngle ?? _mp.maghribMinutesAfterSunset?.toDouble() ?? 0;

  Map<Prayer, double?> run() {
    var times = <Prayer, double>{
      Prayer.imsak: 5,
      Prayer.fajr: 5,
      Prayer.sunrise: 6,
      Prayer.dhuhr: 12,
      Prayer.asr: 13,
      Prayer.sunset: 18,
      Prayer.maghrib: 18,
      Prayer.isha: 18,
    };

    times = _computePrayerTimes(times);
    times = _adjustTimes(times);

    // Night-derived times.
    final diff = params.resolvedMidnightMode == MidnightMode.jafari
        ? _timeDiff(times[Prayer.sunset]!, times[Prayer.fajr]!)
        : _timeDiff(times[Prayer.sunset]!, times[Prayer.sunrise]!);
    times[Prayer.midnight] = times[Prayer.sunset]! + diff / 2;
    times[Prayer.firstThird] = times[Prayer.sunset]! + diff / 3;
    times[Prayer.lastThird] = times[Prayer.sunset]! + 2 * (diff / 3);

    // Moonsighting (or other) twilight override.
    final strategy = twilight;
    if (strategy != null) {
      final ctx = TwilightContext(
        times: Map<Prayer, double?>.from(times),
        date: date,
        coordinates: coordinates,
        shafaq: params.shafaq,
        imsakMinutes: params.imsakMinutes,
      );
      strategy.recalculate(ctx);
      for (final entry in ctx.times.entries) {
        if (entry.value != null) times[entry.key] = entry.value!;
      }
    }

    times = _tuneTimes(times);
    return Map<Prayer, double?>.from(times);
  }

  Map<Prayer, double> _computePrayerTimes(Map<Prayer, double> seeds) {
    // Convert seed hours to day portions.
    final t = <Prayer, double>{
      for (final e in seeds.entries) e.key: e.value / 24,
    };

    final imsak = _sunAngleTime(
        params.imsakMinutes.toDouble(), t[Prayer.imsak]!,
        ccw: true);
    final sunrise =
        _sunAngleTime(_riseSetAngle(), t[Prayer.sunrise]!, ccw: true);
    final fajr = _sunAngleTime(_mp.fajrAngle, t[Prayer.fajr]!, ccw: true);
    final dhuhr = _midDay(t[Prayer.dhuhr]!);
    final asr = _asrTime(params.resolvedShadowFactor, t[Prayer.asr]!);
    final sunset = _sunAngleTime(_riseSetAngle(), t[Prayer.sunset]!);
    final maghrib = _sunAngleTime(_maghribAngle, t[Prayer.maghrib]!);
    final isha = _sunAngleTime(_ishaAngle, t[Prayer.isha]!);

    return <Prayer, double>{
      Prayer.fajr: fajr,
      Prayer.sunrise: sunrise,
      Prayer.dhuhr: dhuhr,
      Prayer.asr: asr,
      Prayer.sunset: sunset,
      Prayer.maghrib: maghrib,
      Prayer.isha: isha,
      Prayer.imsak: imsak,
    };
  }

  Map<Prayer, double> _adjustTimes(Map<Prayer, double> times) {
    final tzHours = params.utcOffset.inSeconds / 3600.0;
    final delta = tzHours - _lng / 15;
    for (final key in times.keys.toList()) {
      times[key] = times[key]! + delta;
    }

    if (params.resolvedHighLatitudeRule != HighLatitudeRule.none) {
      times = _adjustHighLatitudes(times);
    }

    // Imsak is always interval-based (default 10 min before Fajr).
    times[Prayer.imsak] = times[Prayer.fajr]! - params.imsakMinutes / 60;
    if (_mp.maghribIsInterval) {
      times[Prayer.maghrib] =
          times[Prayer.sunset]! + _mp.maghribMinutesAfterSunset! / 60;
    }
    if (_mp.ishaIsInterval) {
      times[Prayer.isha] =
          times[Prayer.maghrib]! + _mp.ishaMinutesAfterMaghrib! / 60;
    }
    times[Prayer.dhuhr] = times[Prayer.dhuhr]! + params.dhuhrMinutes / 60;

    return times;
  }

  Map<Prayer, double> _adjustHighLatitudes(Map<Prayer, double> times) {
    final night = _timeDiff(times[Prayer.sunset]!, times[Prayer.sunrise]!);
    times[Prayer.imsak] = _adjustHLTime(times[Prayer.imsak]!,
        times[Prayer.sunrise]!, params.imsakMinutes.toDouble(), night,
        ccw: true);
    times[Prayer.fajr] = _adjustHLTime(
        times[Prayer.fajr]!, times[Prayer.sunrise]!, _mp.fajrAngle, night,
        ccw: true);
    times[Prayer.isha] = _adjustHLTime(
        times[Prayer.isha]!, times[Prayer.sunset]!, _ishaAngle, night);
    times[Prayer.maghrib] = _adjustHLTime(
        times[Prayer.maghrib]!, times[Prayer.sunset]!, _maghribAngle, night);
    return times;
  }

  double _adjustHLTime(double time, double base, double angle, double night,
      {bool ccw = false}) {
    final portion = _nightPortion(angle, night);
    final diff = ccw ? _timeDiff(time, base) : _timeDiff(base, time);
    if (time.isNaN || diff > portion) {
      return base + (ccw ? -portion : portion);
    }
    return time;
  }

  double _nightPortion(double angle, double night) {
    var portion = 1 / 2; // middle of the night (default)
    switch (params.resolvedHighLatitudeRule) {
      case HighLatitudeRule.angleBased:
        portion = 1 / 60 * angle;
      case HighLatitudeRule.oneSeventh:
        portion = 1 / 7;
      case HighLatitudeRule.middleOfNight:
      case HighLatitudeRule.none:
        break;
    }
    return portion * night;
  }

  double _timeDiff(double t1, double t2) => DegreeMath.fixHour(t2 - t1);

  double _sunAngleTime(double angle, double time, {bool ccw = false}) {
    final jd =
        JulianDate.julian(date.year, date.month, date.day) - _lng / (15 * 24);
    final decl = SunPosition.compute(jd + time).declination;
    final noon = _midDay(time);
    final p1 =
        -DegreeMath.sin(angle) - DegreeMath.sin(decl) * DegreeMath.sin(_lat);
    final p2 = DegreeMath.cos(decl) * DegreeMath.cos(_lat);
    var cosRange = p1 / p2;
    if (cosRange > 1) cosRange = 1;
    if (cosRange < -1) cosRange = -1;
    final t = 1 / 15 * DegreeMath.arccos(cosRange);
    return noon + (ccw ? -t : t);
  }

  double _midDay(double time) {
    final jd =
        JulianDate.julian(date.year, date.month, date.day) - _lng / (15 * 24);
    final eqt = SunPosition.compute(jd + time).equation;
    return DegreeMath.fixHour(12 - eqt);
  }

  double _asrTime(double factor, double time) {
    final jd = JulianDate.gregorianToJulian(date);
    final decl = SunPosition.compute(jd + time).declination;
    final angle =
        -DegreeMath.arccot(factor + DegreeMath.tan((_lat - decl).abs()));
    return _sunAngleTime(angle, time);
  }

  double _riseSetAngle() => 0.833 + 0.0347 * math.sqrt(params.elevation);

  Map<Prayer, double> _tuneTimes(Map<Prayer, double> times) {
    params.tune.toMap().forEach((prayer, minutes) {
      if (minutes != 0 && times.containsKey(prayer)) {
        times[prayer] = times[prayer]! + minutes / 60;
      }
    });
    return times;
  }
}
