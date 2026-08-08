import '../../domain/enums/prayer.dart';
import '../../domain/enums/shafaq.dart';
import '../../domain/ports/twilight_strategy.dart';

/// Moonsighting Committee Worldwide Fajr/Isha twilight.
///
/// Faithful port of islamic-network/prayer-times-moonsighting: a piecewise-linear
/// interpolation of "minutes from sunrise/sunset" driven by the day count from
/// the winter (N) / summer (S) solstice, with per-latitude coefficients.
class MoonsightingTwilight implements TwilightStrategy {
  const MoonsightingTwilight();

  @override
  void recalculate(TwilightContext context) {
    final lat = context.coordinates.latitude;
    final absLat = lat.abs();
    final dyy = _daysFromSolstice(context.date, lat);

    // Fajr — minutes before sunrise.
    final fajrMinutes = _minutes(
      dyy,
      75 + 28.65 / 55 * absLat,
      75 + 19.44 / 55 * absLat,
      75 + 32.74 / 55 * absLat,
      75 + 48.1 / 55 * absLat,
    ).round();
    final sunrise = context.times[Prayer.sunrise];
    if (sunrise != null) {
      final fajr = sunrise - fajrMinutes / 60;
      context.times[Prayer.fajr] = fajr;
      context.times[Prayer.imsak] = fajr - context.imsakMinutes / 60;
    }

    // Isha — minutes after sunset (per shafaq).
    final c = _ishaCoefficients(context.shafaq, absLat);
    final ishaMinutes = _minutes(dyy, c[0], c[1], c[2], c[3]).round();
    final sunset = context.times[Prayer.sunset];
    if (sunset != null) {
      context.times[Prayer.isha] = sunset + ishaMinutes / 60;
    }
  }

  /// Signed whole-day count from the year's solstice, wrapped to `[0, 365]`.
  /// Uses UTC calendar days so results are deterministic (no DST).
  int _daysFromSolstice(DateTime date, double latitude) {
    final year = date.year;
    final solstice =
        latitude > 0 ? DateTime.utc(year, 12, 21) : DateTime.utc(year, 6, 21);
    final d = DateTime.utc(date.year, date.month, date.day);
    final diff = d.difference(solstice).inDays;
    return diff > 0 ? diff : 365 + diff;
  }

  double _minutes(int dyy, double a, double b, double c, double d) {
    if (dyy < 91) return a + (b - a) / 91 * dyy;
    if (dyy < 137) return b + (c - b) / 46 * (dyy - 91);
    if (dyy < 183) return c + (d - c) / 46 * (dyy - 137);
    if (dyy < 229) return d + (c - d) / 46 * (dyy - 183);
    if (dyy < 275) return c + (b - c) / 46 * (dyy - 229);
    return b + (a - b) / 91 * (dyy - 275);
  }

  /// Returns [a, b, c, d] for the given shafaq.
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
