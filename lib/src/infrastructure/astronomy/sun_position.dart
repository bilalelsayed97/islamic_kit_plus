import 'degree_math.dart';

/// The sun's declination and equation of time at a Julian Day.
class SunCoordinates {
  const SunCoordinates(this.declination, this.equation);

  /// Declination in degrees.
  final double declination;

  /// Equation of time in hours.
  final double equation;
}

/// Approximate solar position. Faithful port of `PrayerTimes::sunPosition`.
/// Ref: http://aa.usno.navy.mil/faq/docs/SunApprox.php
class SunPosition {
  const SunPosition._();

  static SunCoordinates compute(double julianDate) {
    final d = julianDate - 2451545.0;
    final g = DegreeMath.fixAngle(357.529 + 0.98560028 * d);
    final q = DegreeMath.fixAngle(280.459 + 0.98564736 * d);
    final l = DegreeMath.fixAngle(
      q + 1.915 * DegreeMath.sin(g) + 0.020 * DegreeMath.sin(2 * g),
    );

    final e = 23.439 - 0.00000036 * d;

    final ra = DegreeMath.arctan2(
          DegreeMath.cos(e) * DegreeMath.sin(l),
          DegreeMath.cos(l),
        ) /
        15;
    final equation = q / 15 - DegreeMath.fixHour(ra);
    final declination =
        DegreeMath.arcsin(DegreeMath.sin(e) * DegreeMath.sin(l));

    return SunCoordinates(declination, equation);
  }
}
