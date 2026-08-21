import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit_plus/src/infrastructure/astronomy/astronomical.dart';
import 'package:islamic_kit_plus/src/infrastructure/astronomy/solar_coordinates.dart';
import 'package:islamic_kit_plus/src/infrastructure/astronomy/solar_time.dart';
import 'package:islamic_kit_plus/islamic_kit_plus.dart';

void main() {
  group('Julian day', () {
    test('Meeus example 7.a — 1957 October 4.81', () {
      expect(
        Astronomical.julianDay(1957, 10, 4, 0.81 * 24),
        closeTo(2436116.31, 0.00001),
      );
    });

    test('the J2000.0 epoch', () {
      expect(Astronomical.julianDay(2000, 1, 1, 12), 2451545.0);
      expect(Astronomical.julianCentury(2451545.0), 0.0);
    });

    test('a Julian century is 36525 days', () {
      expect(
          Astronomical.julianCentury(2451545.0 + 36525), closeTo(1.0, 1e-12));
    });
  });

  // Meeus, Astronomical Algorithms, example 25.a: 1992 October 13 at 0h TD.
  group('Meeus example 25.a — solar position for 1992-10-13', () {
    final jd = Astronomical.julianDay(1992, 10, 13);
    final t = Astronomical.julianCentury(jd);

    test('Julian day and century', () {
      expect(jd, 2448908.5);
      expect(t, closeTo(-0.072183436, 1e-9));
    });

    test('geometric mean longitude', () {
      expect(Astronomical.meanSolarLongitude(t), closeTo(201.80720, 0.00001));
    });

    test('mean anomaly', () {
      expect(Astronomical.meanSolarAnomaly(t), closeTo(278.99397, 0.00001));
    });

    test('equation of the centre', () {
      final m = Astronomical.meanSolarAnomaly(t);
      expect(
        Astronomical.solarEquationOfTheCenter(t, m),
        closeTo(-1.89732, 0.00001),
      );
    });

    test('apparent longitude', () {
      final l0 = Astronomical.meanSolarLongitude(t);
      expect(
        Astronomical.apparentSolarLongitude(t, l0),
        closeTo(199.90895, 0.00002),
      );
    });

    test('mean obliquity of the ecliptic', () {
      expect(
        Astronomical.meanObliquityOfTheEcliptic(t),
        closeTo(23.44023, 0.00001),
      );
    });

    test('apparent right ascension and declination', () {
      final solar = SolarCoordinates(jd);
      expect(solar.rightAscension, closeTo(198.38083, 0.00001));
      expect(solar.declination, closeTo(-7.78507, 0.00001));
    });
  });

  group('Angle helpers', () {
    test('unwindAngle wraps into [0, 360)', () {
      expect(Astronomical.unwindAngle(-45), 315);
      expect(Astronomical.unwindAngle(361), closeTo(1, 1e-12));
      expect(Astronomical.unwindAngle(360), 0);
    });

    test('closestAngle maps into [-180, 180]', () {
      expect(Astronomical.closestAngle(360), 0);
      expect(Astronomical.closestAngle(361), closeTo(1, 1e-12));
      expect(Astronomical.closestAngle(-370), closeTo(-10, 1e-12));
      expect(Astronomical.closestAngle(180), 180);
    });

    test('javaRound breaks ties upward, unlike Dart round()', () {
      expect(Astronomical.javaRound(0.5), 1);
      expect(Astronomical.javaRound(-0.5), 0);
      expect((-0.5).round(), -1); // the behaviour we must not use
      expect(Astronomical.javaRound(2.4), 2);
    });
  });

  group('SolarTime', () {
    test('sunrise and sunset bracket the transit', () {
      final solar = SolarTime(
        year: 2015,
        month: 7,
        day: 12,
        coordinates: const Coordinates(35.7750, -78.6336),
      );
      expect(solar.sunrise, lessThan(solar.transit));
      expect(solar.transit, lessThan(solar.sunset));
    });

    test('the Hanafi Asr falls later than the Shafi Asr', () {
      final solar = SolarTime(
        year: 2015,
        month: 7,
        day: 12,
        coordinates: const Coordinates(35.7750, -78.6336),
      );
      expect(solar.afternoon(2), greaterThan(solar.afternoon(1)));
    });

    test('an unreachable angle yields NaN', () {
      // Stockholm at the solstice never reaches 18° below the horizon.
      final solar = SolarTime(
        year: 2024,
        month: 6,
        day: 21,
        coordinates: const Coordinates(59.3293, 18.0686),
      );
      expect(solar.sunrise.isNaN, isFalse);
      expect(solar.hourAngle(-18, afterTransit: false).isNaN, isTrue);
    });

    test('elevation brings sunrise earlier and sunset later', () {
      const coordinates = Coordinates(21.4225, 39.8262);
      final sea = SolarTime(
        year: 2024,
        month: 6,
        day: 21,
        coordinates: coordinates,
      );
      final high = SolarTime(
        year: 2024,
        month: 6,
        day: 21,
        coordinates: coordinates,
        elevation: 1000,
      );
      expect(high.sunrise, lessThan(sea.sunrise));
      expect(high.sunset, greaterThan(sea.sunset));
      expect(high.transit, sea.transit);
    });
  });
}
