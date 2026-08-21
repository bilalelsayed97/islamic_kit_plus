import 'astronomical.dart';

/// The sun's apparent equatorial coordinates for one Julian Day.
///
/// All three values are needed to interpolate the sun's position across a day,
/// which is what gives the Meeus algorithm its accuracy over the simpler
/// single-sample formulas.
class SolarCoordinates {
  /// Computes the sun's coordinates for [julianDay].
  factory SolarCoordinates(double julianDay) {
    final t = Astronomical.julianCentury(julianDay);
    final meanSolarLongitude = Astronomical.meanSolarLongitude(t);
    final meanLunarLongitude = Astronomical.meanLunarLongitude(t);
    final ascendingNode = Astronomical.ascendingLunarNodeLongitude(t);
    final apparentLongitude =
        Astronomical.apparentSolarLongitude(t, meanSolarLongitude);

    final meanSiderealTime = Astronomical.meanSiderealTime(t);
    final nutationLongitude = Astronomical.nutationInLongitude(
      t,
      meanSolarLongitude,
      meanLunarLongitude,
      ascendingNode,
    );
    final nutationObliquity = Astronomical.nutationInObliquity(
      t,
      meanSolarLongitude,
      meanLunarLongitude,
      ascendingNode,
    );

    final meanObliquity = Astronomical.meanObliquityOfTheEcliptic(t);
    final apparentObliquity =
        Astronomical.apparentObliquityOfTheEcliptic(t, meanObliquity);

    // Meeus equations 25.6 / 25.7 — apparent declination and right ascension.
    final declination = Astronomical.arcsin(
      Astronomical.sin(apparentObliquity) * Astronomical.sin(apparentLongitude),
    );
    final rightAscension = Astronomical.unwindAngle(
      Astronomical.arctan2(
        Astronomical.cos(apparentObliquity) *
            Astronomical.sin(apparentLongitude),
        Astronomical.cos(apparentLongitude),
      ),
    );
    final apparentSiderealTime = meanSiderealTime +
        (nutationLongitude *
                3600 *
                Astronomical.cos(meanObliquity + nutationObliquity)) /
            3600;

    return SolarCoordinates._(
      declination: declination,
      rightAscension: rightAscension,
      apparentSiderealTime: apparentSiderealTime,
    );
  }

  const SolarCoordinates._({
    required this.declination,
    required this.rightAscension,
    required this.apparentSiderealTime,
  });

  /// Apparent declination of the sun, in degrees.
  final double declination;

  /// Apparent right ascension of the sun, in degrees.
  final double rightAscension;

  /// Apparent sidereal time at Greenwich, in degrees.
  final double apparentSiderealTime;
}
