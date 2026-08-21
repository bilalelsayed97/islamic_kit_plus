import 'dart:math' as math;

/// Degree-based trigonometry and the solar-position formulas of Jean Meeus'
/// *Astronomical Algorithms* (2nd ed.).
///
/// Every angle is in degrees unless the name says otherwise; times are
/// fractional hours. The constants, the operation order and the
/// integer-truncation points are all deliberate — they keep results agreeing
/// with the published reference to the second.
class Astronomical {
  const Astronomical._();

  static const double _degToRad = math.pi / 180.0;
  static const double _radToDeg = 180.0 / math.pi;

  /// Altitude of the sun's centre at apparent sunrise/sunset: −0.833°, which
  /// folds together atmospheric refraction and the solar semi-diameter.
  static const double horizonAltitude = -0.833333333333333;

  // ---------------------------------------------------------------------------
  // Degree trigonometry
  // ---------------------------------------------------------------------------

  static double sin(double degrees) => math.sin(degrees * _degToRad);

  static double cos(double degrees) => math.cos(degrees * _degToRad);

  static double tan(double degrees) => math.tan(degrees * _degToRad);

  static double arcsin(double value) => math.asin(value) * _radToDeg;

  static double arccos(double value) => math.acos(value) * _radToDeg;

  static double arctan(double value) => math.atan(value) * _radToDeg;

  static double arctan2(double y, double x) => math.atan2(y, x) * _radToDeg;

  // ---------------------------------------------------------------------------
  // Numeric helpers
  // ---------------------------------------------------------------------------

  /// Rounds half **up**, i.e. `floor(x + 0.5)`.
  ///
  /// Dart's `round()` rounds half *away from zero*, which disagrees on exact
  /// negative halves (`-0.5` → `0` here, `-1` there). The published tables
  /// assume half-up, so every rounding step goes through this.
  static int javaRound(double value) => (value + 0.5).floor();

  /// Wraps [value] into `[0, max)`.
  static double normalizeWithBound(double value, double max) =>
      value - max * (value / max).floorToDouble();

  /// Wraps an angle into `[0, 360)`.
  static double unwindAngle(double value) => normalizeWithBound(value, 360.0);

  /// Maps an angle into `[-180, 180]`.
  static double closestAngle(double angle) {
    if (angle >= -180.0 && angle <= 180.0) return angle;
    return angle - 360.0 * javaRound(angle / 360.0);
  }

  // ---------------------------------------------------------------------------
  // Julian day
  // ---------------------------------------------------------------------------

  /// Julian Day for a Gregorian calendar date at [hours] UTC.
  ///
  /// Meeus, *Astronomical Algorithms*, chapter 7. The integer truncations are
  /// intentional — the formula is defined in terms of them.
  static double julianDay(int year, int month, int day, [double hours = 0]) {
    var y = year;
    var m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = y ~/ 100;
    final b = (2 - a) + (a ~/ 4);

    return ((y + 4716) * 365.25).truncateToDouble() +
        ((m + 1) * 30.6001).truncateToDouble() +
        (day + hours / 24.0) +
        b -
        1524.5;
  }

  /// Julian centuries since the J2000.0 epoch.
  static double julianCentury(double julianDay) =>
      (julianDay - 2451545.0) / 36525.0;

  // ---------------------------------------------------------------------------
  // Solar position (Meeus)
  // ---------------------------------------------------------------------------

  /// Geometric mean longitude of the sun, in degrees.
  static double meanSolarLongitude(double t) =>
      unwindAngle(280.4664567 + 36000.76983 * t + 0.0003032 * t * t);

  /// Geometric mean longitude of the moon, in degrees.
  static double meanLunarLongitude(double t) =>
      unwindAngle(218.3165 + 481267.8813 * t);

  /// Mean anomaly of the sun, in degrees.
  static double meanSolarAnomaly(double t) =>
      unwindAngle(357.52911 + 35999.05029 * t - 0.0001537 * t * t);

  /// Longitude of the ascending node of the lunar orbit, in degrees.
  static double ascendingLunarNodeLongitude(double t) => unwindAngle(
        125.04452 -
            1934.136261 * t +
            0.0020708 * t * t +
            (t * t * t) / 450000.0,
      );

  /// The sun's equation of the centre, in degrees, for mean anomaly [m].
  static double solarEquationOfTheCenter(double t, double m) {
    final mRad = m * _degToRad;
    return (1.914602 - 0.004817 * t - 0.000014 * t * t) * math.sin(mRad) +
        (0.019993 - 0.000101 * t) * math.sin(2 * mRad) +
        0.000289 * math.sin(3 * mRad);
  }

  /// Apparent longitude of the sun (nutation and aberration applied).
  static double apparentSolarLongitude(double t, double meanLongitude) {
    final longitude = meanLongitude +
        solarEquationOfTheCenter(t, meanSolarAnomaly(t)) -
        0.00569 -
        0.00478 * sin(125.04 - 1934.136 * t);
    return unwindAngle(longitude);
  }

  /// Mean obliquity of the ecliptic, in degrees.
  static double meanObliquityOfTheEcliptic(double t) =>
      23.439291 -
      0.013004167 * t -
      0.0000001639 * t * t +
      0.0000005036 * t * t * t;

  /// Apparent obliquity of the ecliptic, in degrees.
  static double apparentObliquityOfTheEcliptic(
    double t,
    double meanObliquity,
  ) =>
      meanObliquity + 0.00256 * cos(125.04 - 1934.136 * t);

  /// Mean sidereal time at Greenwich, in degrees.
  static double meanSiderealTime(double t) {
    final jd = t * 36525.0 + 2451545.0;
    final theta = 280.46061837 +
        360.98564736629 * (jd - 2451545.0) +
        0.000387933 * t * t -
        (t * t * t) / 38710000.0;
    return unwindAngle(theta);
  }

  /// Nutation in longitude, in degrees.
  static double nutationInLongitude(
    double t,
    double solarLongitude,
    double lunarLongitude,
    double ascendingNode,
  ) {
    return (-17.2 / 3600) * sin(ascendingNode) -
        (1.32 / 3600) * sin(2 * solarLongitude) -
        (0.23 / 3600) * sin(2 * lunarLongitude) +
        (0.21 / 3600) * sin(2 * ascendingNode);
  }

  /// Nutation in obliquity, in degrees.
  static double nutationInObliquity(
    double t,
    double solarLongitude,
    double lunarLongitude,
    double ascendingNode,
  ) {
    return (9.2 / 3600) * cos(ascendingNode) +
        (0.57 / 3600) * cos(2 * solarLongitude) +
        (0.10 / 3600) * cos(2 * lunarLongitude) -
        (0.09 / 3600) * cos(2 * ascendingNode);
  }

  /// Altitude of a celestial body above the horizon, in degrees.
  static double altitudeOfCelestialBody(
    double observerLatitude,
    double declination,
    double localHourAngle,
  ) {
    return arcsin(
      sin(observerLatitude) * sin(declination) +
          cos(observerLatitude) * cos(declination) * cos(localHourAngle),
    );
  }

  // ---------------------------------------------------------------------------
  // Transit and hour angles
  // ---------------------------------------------------------------------------

  /// Approximate transit as a fraction of the day.
  static double approximateTransit(
    double longitude,
    double siderealTime,
    double rightAscension,
  ) {
    final lw = longitude * -1;
    return normalizeWithBound((rightAscension + lw - siderealTime) / 360, 1);
  }

  /// Transit time (fractional hours) corrected by interpolation.
  static double correctedTransit(
    double approximateTransit,
    double longitude,
    double siderealTime,
    double rightAscension,
    double previousRightAscension,
    double nextRightAscension,
  ) {
    final lw = longitude * -1;
    final theta = unwindAngle(siderealTime + 360.985647 * approximateTransit);
    final alpha = unwindAngle(
      interpolateAngles(
        rightAscension,
        previousRightAscension,
        nextRightAscension,
        approximateTransit,
      ),
    );
    final h = closestAngle(theta - lw - alpha);
    final deltaM = h / -360;
    return (approximateTransit + deltaM) * 24;
  }

  /// Time (fractional hours) at which the sun reaches altitude [altitude].
  ///
  /// Returns `double.nan` when the sun never reaches that altitude on the day.
  static double correctedHourAngle({
    required double approximateTransit,
    required double altitude,
    required double latitude,
    required double longitude,
    required bool afterTransit,
    required double siderealTime,
    required double rightAscension,
    required double previousRightAscension,
    required double nextRightAscension,
    required double declination,
    required double previousDeclination,
    required double nextDeclination,
  }) {
    final lw = longitude * -1;

    final term = (sin(altitude) - sin(latitude) * sin(declination)) /
        (cos(latitude) * cos(declination));
    // acos() outside [-1, 1] yields NaN, which propagates: the caller treats a
    // NaN result as "the sun never reaches this angle today".
    final h0 = arccos(term) / 360;

    final m = afterTransit ? approximateTransit + h0 : approximateTransit - h0;
    final theta = unwindAngle(siderealTime + 360.985647 * m);
    final alpha = unwindAngle(
      interpolateAngles(
        rightAscension,
        previousRightAscension,
        nextRightAscension,
        m,
      ),
    );
    final delta = interpolate(
      declination,
      previousDeclination,
      nextDeclination,
      m,
    );
    final h = (theta - lw) - alpha;
    final altitudeOfSun = altitudeOfCelestialBody(latitude, delta, h);
    final deltaM = (altitudeOfSun - altitude) /
        (360 * cos(delta) * cos(latitude) * sin(h));
    return (m + deltaM) * 24;
  }

  /// Three-point interpolation of a value. Meeus chapter 3.
  static double interpolate(
    double value,
    double previousValue,
    double nextValue,
    double factor,
  ) {
    final a = value - previousValue;
    final b = nextValue - value;
    final c = b - a;
    return value + ((factor / 2) * (a + b + factor * c));
  }

  /// Three-point interpolation of an angle (each difference unwound first).
  static double interpolateAngles(
    double value,
    double previousValue,
    double nextValue,
    double factor,
  ) {
    final a = unwindAngle(value - previousValue);
    final b = unwindAngle(nextValue - value);
    final c = b - a;
    return value + ((factor / 2) * (a + b + factor * c));
  }
}
