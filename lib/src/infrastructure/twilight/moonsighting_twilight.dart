import '../../domain/enums/shafaq.dart';
import '../../domain/ports/twilight_strategy.dart';
import '../astronomy/astronomical.dart';

/// Moonsighting Committee Worldwide Fajr/Isha twilight.
///
/// A piecewise-linear interpolation of "minutes from sunrise/sunset" driven by
/// the day count since the winter (northern) or summer (southern) solstice,
/// with per-latitude coefficients, as published by the committee.
class MoonsightingTwilight implements TwilightStrategy {
  const MoonsightingTwilight();

  @override
  int fajrSecondsBeforeSunrise(DateTime date, double latitude) {
    final absLat = latitude.abs();
    final minutes = _interpolate(
      _daysSinceSolstice(date, latitude),
      75 + 28.65 / 55.0 * absLat,
      75 + 19.44 / 55.0 * absLat,
      75 + 32.74 / 55.0 * absLat,
      75 + 48.10 / 55.0 * absLat,
    );
    return Astronomical.javaRound(minutes * 60.0);
  }

  @override
  int ishaSecondsAfterSunset(
    DateTime date,
    double latitude,
    Shafaq shafaq,
  ) {
    final absLat = latitude.abs();
    final c = _ishaCoefficients(shafaq, absLat);
    final minutes = _interpolate(
      _daysSinceSolstice(date, latitude),
      c[0],
      c[1],
      c[2],
      c[3],
    );
    return Astronomical.javaRound(minutes * 60.0);
  }

  /// Whole days since the hemisphere's solstice, wrapped into the year.
  ///
  /// Derived from the day-of-year rather than a date subtraction so that leap
  /// years and the New Year boundary land on the published day.
  int _daysSinceSolstice(DateTime date, double latitude) {
    final year = date.year;
    final leap = _isLeapYear(year);
    final daysInYear = leap ? 366 : 365;
    final dayOfYear = _dayOfYear(date);

    if (latitude >= 0) {
      // The December solstice sits 10 days before year-end.
      final days = dayOfYear + 10;
      return days >= daysInYear ? days - daysInYear : days;
    }
    final southernOffset = leap ? 173 : 172;
    final days = dayOfYear - southernOffset;
    return days < 0 ? days + daysInYear : days;
  }

  int _dayOfYear(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day)
          .difference(DateTime.utc(date.year))
          .inDays +
      1;

  bool _isLeapYear(int year) =>
      year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

  double _interpolate(int dyy, double a, double b, double c, double d) {
    if (dyy < 91) return a + (b - a) / 91 * dyy;
    if (dyy < 137) return b + (c - b) / 46 * (dyy - 91);
    if (dyy < 183) return c + (d - c) / 46 * (dyy - 137);
    if (dyy < 229) return d + (c - d) / 46 * (dyy - 183);
    if (dyy < 275) return c + (b - c) / 46 * (dyy - 229);
    return b + (a - b) / 91 * (dyy - 275);
  }

  /// Returns the `[a, b, c, d]` seasonal coefficients for [shafaq].
  List<double> _ishaCoefficients(Shafaq shafaq, double absLat) {
    switch (shafaq) {
      case Shafaq.ahmer:
        return <double>[
          62 + 17.4 / 55.0 * absLat,
          62 - 7.16 / 55.0 * absLat,
          62 + 5.12 / 55.0 * absLat,
          62 + 19.44 / 55.0 * absLat,
        ];
      case Shafaq.abyad:
        return <double>[
          75 + 25.6 / 55.0 * absLat,
          75 + 7.16 / 55.0 * absLat,
          75 + 36.84 / 55.0 * absLat,
          75 + 81.84 / 55.0 * absLat,
        ];
      case Shafaq.general:
        return <double>[
          75 + 25.6 / 55.0 * absLat,
          75 + 2.05 / 55.0 * absLat,
          75 - 9.21 / 55.0 * absLat,
          75 + 6.14 / 55.0 * absLat,
        ];
    }
  }
}
