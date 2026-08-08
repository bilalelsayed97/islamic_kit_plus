import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit_plus/islamic_kit_plus.dart';

void main() {
  final service = PrayerTimesService();

  // London — matches islamic-network/prayer-times TimingsTest::testTimes.
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
      Prayer.dhuhr: '12:59',
      Prayer.asr: '16:54',
      Prayer.sunset: '20:12',
      Prayer.maghrib: '20:12',
      Prayer.isha: '22:02',
      Prayer.imsak: '03:47',
      Prayer.midnight: '00:59',
    };

    expected.forEach((prayer, time) {
      test('${prayer.key} == $time', () {
        expect(result.formatted(prayer), time);
      });
    });
  });

  group('ISO-8601 with day rollover', () {
    const isoParams = CalculationParameters(
      method: CalculationMethod.isna,
      utcOffset: Duration(hours: 1),
    );

    test('mid-latitude Fajr', () {
      final r = service.timings(DateTime(2014, 4, 24), london, isoParams);
      expect(
        r.formatted(Prayer.fajr, TimeFormat.iso8601),
        '2014-04-24T03:57:00+01:00',
      );
    });

    test('high latitude — Isha rolls to next day', () {
      final r = service.timings(
        DateTime(2014, 4, 24),
        const Coordinates(70, -10),
        isoParams,
      );
      expect(
        r.formatted(Prayer.isha, TimeFormat.iso8601),
        '2014-04-25T00:04:00+01:00',
      );
    });

    test('high latitude — Fajr rolls to previous day', () {
      final r = service.timings(
        DateTime(2014, 4, 24),
        const Coordinates(70, 40),
        isoParams,
      );
      expect(
        r.formatted(Prayer.fajr, TimeFormat.iso8601),
        '2014-04-23T23:55:00+01:00',
      );
    });
  });

  test('extreme latitude never yields invalid times (Karachi method)', () {
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
  });

  group('Next prayer', () {
    test('after Dhuhr returns Asr', () {
      final next = service.nextPrayer(
        DateTime(2014, 4, 24, 13, 30),
        london,
        londonParams,
      );
      expect(next.prayer, Prayer.asr);
      expect(next.time.format(), '16:54');
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
