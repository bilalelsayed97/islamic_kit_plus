import 'dart:math' as math;

import '../../domain/value_objects/coordinates.dart';
import 'astronomical.dart';
import 'solar_coordinates.dart';

/// Solar events for one civil date at one location, in fractional **UTC**
/// hours measured from 00:00 UTC of that date.
///
/// Coordinates are computed for the previous, current and next day so that
/// right ascension and declination can be interpolated to the moment of each
/// event — the step that separates this from single-sample approximations and
/// keeps results accurate to the second.
///
/// Values may fall outside `[0, 24)` when an event lands on an adjacent UTC
/// day; the raw value is kept so day rollover survives. A `double.nan` result
/// means the sun never reaches the requested altitude on that date.
class SolarTime {
  /// Computes the solar events for [year]/[month]/[day] at [coordinates].
  ///
  /// [elevation] is the observer's height above sea level in metres. It dips
  /// the apparent horizon by `0.0347 · √metres` degrees, bringing sunrise
  /// earlier and sunset later. This is a package extension the reference
  /// standard algorithm does not model; at `0` the behaviour is identical.
  factory SolarTime({
    required int year,
    required int month,
    required int day,
    required Coordinates coordinates,
    double elevation = 0,
  }) {
    final julianDay = Astronomical.julianDay(year, month, day);
    // JD is continuous, so ±1 is exactly the adjacent civil day at 0h UTC.
    final solar = SolarCoordinates(julianDay);
    final previous = SolarCoordinates(julianDay - 1);
    final next = SolarCoordinates(julianDay + 1);

    final approximateTransit = Astronomical.approximateTransit(
      coordinates.longitude,
      solar.apparentSiderealTime,
      solar.rightAscension,
    );

    final transit = Astronomical.correctedTransit(
      approximateTransit,
      coordinates.longitude,
      solar.apparentSiderealTime,
      solar.rightAscension,
      previous.rightAscension,
      next.rightAscension,
    );

    final horizon = elevation > 0
        ? Astronomical.horizonAltitude - 0.0347 * math.sqrt(elevation)
        : Astronomical.horizonAltitude;

    double angleTime(double altitude, {required bool afterTransit}) {
      return Astronomical.correctedHourAngle(
        approximateTransit: approximateTransit,
        altitude: altitude,
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        afterTransit: afterTransit,
        siderealTime: solar.apparentSiderealTime,
        rightAscension: solar.rightAscension,
        previousRightAscension: previous.rightAscension,
        nextRightAscension: next.rightAscension,
        declination: solar.declination,
        previousDeclination: previous.declination,
        nextDeclination: next.declination,
      );
    }

    return SolarTime._(
      coordinates: coordinates,
      solar: solar,
      previous: previous,
      next: next,
      approximateTransit: approximateTransit,
      transit: transit,
      sunrise: angleTime(horizon, afterTransit: false),
      sunset: angleTime(horizon, afterTransit: true),
    );
  }

  const SolarTime._({
    required this.coordinates,
    required SolarCoordinates solar,
    required SolarCoordinates previous,
    required SolarCoordinates next,
    required this.approximateTransit,
    required this.transit,
    required this.sunrise,
    required this.sunset,
  })  : _solar = solar,
        _previous = previous,
        _next = next;

  final Coordinates coordinates;
  final SolarCoordinates _solar;
  final SolarCoordinates _previous;
  final SolarCoordinates _next;

  /// Approximate transit as a fraction of the day (interpolation seed).
  final double approximateTransit;

  /// Solar transit — Dhuhr's astronomical basis. Fractional UTC hours.
  final double transit;

  /// Apparent sunrise, fractional UTC hours.
  final double sunrise;

  /// Apparent sunset, fractional UTC hours.
  final double sunset;

  /// Time at which the sun's centre sits at [altitude] degrees (negative =
  /// below the horizon), before or after transit. Fractional UTC hours.
  double hourAngle(double altitude, {required bool afterTransit}) {
    return Astronomical.correctedHourAngle(
      approximateTransit: approximateTransit,
      altitude: altitude,
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      afterTransit: afterTransit,
      siderealTime: _solar.apparentSiderealTime,
      rightAscension: _solar.rightAscension,
      previousRightAscension: _previous.rightAscension,
      nextRightAscension: _next.rightAscension,
      declination: _solar.declination,
      previousDeclination: _previous.declination,
      nextDeclination: _next.declination,
    );
  }

  /// Time at which an object's shadow has grown by [shadowFactor] times its
  /// own length beyond its shadow at transit — the Asr definition (1 for
  /// Shafi'i/Maliki/Hanbali, 2 for Hanafi). Fractional UTC hours.
  double afternoon(double shadowFactor) {
    final tangent = (coordinates.latitude - _solar.declination).abs();
    final inverse = shadowFactor + Astronomical.tan(tangent);
    return hourAngle(Astronomical.arctan(1.0 / inverse), afterTransit: true);
  }
}
