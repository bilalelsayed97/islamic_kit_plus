import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit_plus/islamic_kit_plus.dart';

void main() {
  final service = PrayerTimesService();

  // Reference vector published with the Adhan library. If the solar algorithm
  // is ported correctly, every one of these matches to the minute.
  group('Adhan reference — Raleigh NC 2015-07-12, ISNA', () {
    const raleigh = Coordinates(35.7750, -78.6336);
    const params = CalculationParameters(
      method: CalculationMethod.isna,
      school: AsrSchool.hanafi,
      utcOffset: Duration(hours: -4), // America/New_York, EDT
    );

    late PrayerResult result;
    setUp(() {
      result = service.timings(DateTime(2015, 7, 12), raleigh, params);
    });

    final expected = <Prayer, String>{
      Prayer.fajr: '4:42 am',
      Prayer.sunrise: '6:08 am',
      Prayer.dhuhr: '1:21 pm',
      Prayer.asr: '6:22 pm',
      Prayer.maghrib: '8:32 pm',
      Prayer.isha: '9:57 pm',
    };

    expected.forEach((prayer, time) {
      test('${prayer.key} == $time', () {
        expect(result.formatted(prayer, TimeFormat.h12), time);
      });
    });

    test('Shafi Asr differs from Hanafi', () {
      final shafi = service.timings(
        DateTime(2015, 7, 12),
        raleigh,
        params.copyWith(school: AsrSchool.standard),
      );
      expect(shafi.formatted(Prayer.asr, TimeFormat.h12), '5:09 pm');
    });
  });

  const london = Coordinates(51.508515, -0.1254872);
  const londonParams = CalculationParameters(
    method: CalculationMethod.isna,
    utcOffset: Duration(hours: 1), // Europe/London, BST on 2014-04-24
  );

  group('ISNA London 2014-04-24 (24h)', () {
    late PrayerResult result;
    setUp(() {
      result = service.timings(DateTime(2014, 4, 24), london, londonParams);
    });

    final expected = <Prayer, String>{
      Prayer.fajr: '03:57',
      Prayer.sunrise: '05:46',
      // ISNA publishes Dhuhr a minute past the zenith.
      Prayer.dhuhr: '13:00',
      Prayer.asr: '16:56',
      Prayer.sunset: '20:12',
      Prayer.maghrib: '20:12',
      Prayer.isha: '22:02',
      Prayer.imsak: '03:47',
      // Night measured sunset -> next Fajr (the engine's default basis).
      Prayer.midnight: '00:05',
      Prayer.firstThird: '22:47',
      Prayer.lastThird: '01:22',
    };

    expected.forEach((prayer, time) {
      test('${prayer.key} == $time', () {
        expect(result.formatted(prayer), time);
      });
    });
  });

  group('Midnight basis', () {
    test('standard mode measures sunset to sunrise', () {
      final r = service.timings(
        DateTime(2014, 4, 24),
        london,
        londonParams.copyWith(midnightMode: MidnightMode.standard),
      );
      expect(r.formatted(Prayer.midnight), '00:59');
    });

    test('default (jafari) measures sunset to Fajr', () {
      final r = service.timings(DateTime(2014, 4, 24), london, londonParams);
      expect(r.formatted(Prayer.midnight), '00:05');
    });
  });

  group('ISO-8601 with day rollover', () {
    test('mid-latitude Fajr', () {
      final r = service.timings(DateTime(2014, 4, 24), london, londonParams);
      expect(
        r.formatted(Prayer.fajr, TimeFormat.iso8601),
        '2014-04-24T03:57:00+01:00',
      );
    });

    test('high latitude — Isha rolls to next day', () {
      final r = service.timings(
        DateTime(2014, 4, 24),
        const Coordinates(70, -10),
        londonParams,
      );
      expect(
        r.formatted(Prayer.isha, TimeFormat.iso8601),
        '2014-04-25T01:40:00+01:00',
      );
    });

    test('high latitude — Fajr rolls to previous day', () {
      final r = service.timings(
        DateTime(2014, 4, 24),
        const Coordinates(70, 40),
        londonParams,
      );
      expect(
        r.formatted(Prayer.fajr, TimeFormat.iso8601),
        '2014-04-23T22:20:00+01:00',
      );
    });
  });

  group('High latitude', () {
    test('safe bounds keep every time valid where the sun still rises', () {
      final r = service.timings(
        DateTime(2018, 1, 19),
        const Coordinates(67.104732, 67.104732),
        const CalculationParameters(
          method: CalculationMethod.karachi,
          utcOffset: Duration(hours: 5), // Asia/Yekaterinburg
        ),
      );
      for (final prayer in Prayer.values) {
        expect(r.formatted(prayer), isNot(invalidTime), reason: prayer.key);
      }
    });

    test('polar night invalidates the whole day', () {
      final r = service.timings(
        DateTime(2024, 12, 15),
        const Coordinates(78.2232, 15.6469), // Longyearbyen
        const CalculationParameters(utcOffset: Duration(hours: 1)),
      );
      for (final prayer in Prayer.values) {
        expect(r.formatted(prayer), invalidTime, reason: prayer.key);
      }
    });

    test('rule none leaves an unreachable angle invalid', () {
      // Stockholm at the solstice: the sun sets, but never falls 18° below
      // the horizon, so Fajr and Isha have no angle-based solution.
      const stockholm = Coordinates(59.3293, 18.0686);
      const params = CalculationParameters(utcOffset: Duration(hours: 2));

      final none = service.timings(
        DateTime(2024, 6, 21),
        stockholm,
        params.copyWith(highLatitudeRule: HighLatitudeRule.none),
      );
      expect(none.formatted(Prayer.sunrise), '03:31');
      expect(none.formatted(Prayer.fajr), invalidTime);
      expect(none.formatted(Prayer.isha), invalidTime);

      // The default rule bounds both at the middle of the night instead.
      final bounded = service.timings(DateTime(2024, 6, 21), stockholm, params);
      expect(bounded.formatted(Prayer.fajr), '00:50');
      expect(bounded.formatted(Prayer.isha), '00:50');
    });
  });

  group('Moonsighting London 2014-04-24', () {
    late PrayerResult result;
    setUp(() {
      result = service.timings(
        DateTime(2014, 4, 24),
        london,
        const CalculationParameters(
          method: CalculationMethod.moonsighting,
          utcOffset: Duration(hours: 1),
        ),
      );
    });

    test('Fajr == 04:04', () => expect(result.formatted(Prayer.fajr), '04:04'));
    test('Isha == 21:21', () => expect(result.formatted(Prayer.isha), '21:21'));
    test('Imsak == 03:54',
        () => expect(result.formatted(Prayer.imsak), '03:54'));
    test('Sunrise unchanged (05:46)',
        () => expect(result.formatted(Prayer.sunrise), '05:46'));
    test('method adjustments move Dhuhr +5 and Maghrib +3', () {
      expect(result.formatted(Prayer.dhuhr), '13:04');
      expect(result.formatted(Prayer.maghrib), '20:15');
    });
  });

  group('Umm al-Qura Ramadan Isha interval', () {
    const makkah = Coordinates(21.4225, 39.8262);
    const params = CalculationParameters(
      method: CalculationMethod.makkah,
      utcOffset: Duration(hours: 3),
    );

    int gapMinutes(PrayerResult r) {
      final maghrib = r.timings.time(Prayer.maghrib).hours!;
      final isha = r.timings.time(Prayer.isha).hours!;
      return ((isha - maghrib) * 60).round();
    }

    test('inside Ramadan the interval is 120 minutes', () {
      // 1447 AH Ramadan runs from roughly 2026-02-18.
      final r = service.timings(DateTime(2026, 2, 20), makkah, params);
      expect(gapMinutes(r), 120);
    });

    test('outside Ramadan the interval is 90 minutes', () {
      final r = service.timings(DateTime(2026, 4, 20), makkah, params);
      expect(gapMinutes(r), 90);
    });

    test('no other method varies by month', () {
      final r = service.timings(
        DateTime(2026, 2, 20),
        makkah,
        params.copyWith(method: CalculationMethod.qatar),
      );
      expect(gapMinutes(r), 90);
    });
  });

  group('Next prayer', () {
    test('after Dhuhr returns Asr', () {
      final next = service.nextPrayer(
        DateTime(2014, 4, 24, 13, 30),
        london,
        londonParams,
      );
      expect(next.prayer, Prayer.asr);
      expect(next.time.format(), '16:56');
    });

    test('after Isha rolls to next day Fajr', () {
      final next = service.nextPrayer(
        DateTime(2014, 4, 24, 23, 30),
        london,
        londonParams,
      );
      expect(next.prayer, Prayer.fajr);
      expect(next.onDate, DateTime(2014, 4, 25));
    });
  });

  group('Calendars', () {
    test('monthly calendar has one entry per day', () {
      final month = service.monthlyCalendar(2014, 4, london, londonParams);
      expect(month.length, 30);
      expect(month.first.formatted(Prayer.fajr), isNotEmpty);
    });

    test('annual calendar keyed by 12 months', () {
      final year = service.annualCalendar(2014, london, londonParams);
      expect(year.keys.toList(), List<int>.generate(12, (i) => i + 1));
      expect(year[1]!.length, 31);
    });

    test('range calendar rejects > 11 months', () {
      expect(
        () => service.rangeCalendar(
          DateTime(2014, 1, 1),
          DateTime(2015, 1, 1),
          london,
          londonParams,
        ),
        throwsArgumentError,
      );
    });
  });
}
