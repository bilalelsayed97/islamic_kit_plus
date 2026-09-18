import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit_plus/islamic_kit_plus.dart';
import 'package:islamic_kit_plus/src/infrastructure/calendar/data/hijri_sightings.dart';
import 'package:islamic_kit_plus/src/infrastructure/calendar/table_hijri_converter.dart';

/// The two directions of a converter must be inverses: a Hijri calendar screen
/// places a month with `toGregorian` and labels its days with `fromGregorian`,
/// so any disagreement shows up as a month that starts on "day 2".
void main() {
  const factory = HijriConverterFactory();

  DateTime dateOf((int, int, int) ymd) => DateTime.utc(ymd.$1, ymd.$2, ymd.$3);

  void expectRoundTrips(CalendarMethod method, DateTime from, DateTime to) {
    final converter = factory.create(method);
    // UTC, stepped by calendar day: no DST can skip or repeat a date.
    for (var date = from;
        !date.isAfter(to);
        date = DateTime.utc(date.year, date.month, date.day + 1)) {
      final hijri = converter.fromGregorian(date);
      final back = converter.toGregorian(hijri.year, hijri.month, hijri.day);
      expect(
        (back.year, back.month, back.day),
        (date.year, date.month, date.day),
        reason: '${method.code}: $date is ${hijri.formatted}',
      );
    }
  }

  test('Umm al-Qura round-trips every day of its table', () {
    const table = TableHijriConverter.ummAlQura();
    expectRoundTrips(
      CalendarMethod.uaq,
      dateOf(table.gregorianFrom),
      dateOf(table.gregorianTo),
    );
  });

  test('Diyanet round-trips every day of its table', () {
    const table = TableHijriConverter.diyanet();
    expectRoundTrips(
      CalendarMethod.diyanet,
      dateOf(table.gregorianFrom),
      dateOf(table.gregorianTo),
    );
  });

  test('Mathematical round-trips', () {
    expectRoundTrips(
      CalendarMethod.mathematical,
      DateTime.utc(1990),
      DateTime.utc(2040, 12, 31),
    );
  });

  // Before it, an announcement moves single days of a month, which the
  // surrounding days (still read off the table) cannot mirror.
  test('HJCoSA round-trips every day after its last announcement', () {
    expectRoundTrips(
      CalendarMethod.hjcosa,
      DateTime.utc(2021, 9, 9),
      dateOf(const TableHijriConverter.ummAlQura().gregorianTo),
    );
  });

  test('HJCoSA round-trips every announced date', () {
    final converter = factory.create(CalendarMethod.hjcosa);
    for (final gregorian in kHjcosaSightings.keys) {
      final p = gregorian.split('-').map(int.parse).toList();
      final date = DateTime(p[2], p[1], p[0]);
      final hijri = converter.fromGregorian(date);
      expect(
        converter.toGregorian(hijri.year, hijri.month, hijri.day),
        date,
        reason: gregorian,
      );
    }
  });

  // The arithmetic calendar put these on the 24th, the 17th and the 17th.
  test('the months that used to start a day off', () {
    final hjcosa = factory.create(CalendarMethod.hjcosa);
    expect(hjcosa.toGregorian(1447, 4, 1), DateTime(2025, 9, 23));
    expect(hjcosa.toGregorian(1448, 1, 1), DateTime(2026, 6, 16));
    expect(hjcosa.toGregorian(1448, 2, 1), DateTime(2026, 7, 15));
  });

  // Sha'ban 1446 has 29 days.
  test("a day past the month's end runs into the next month", () {
    final uaq = factory.create(CalendarMethod.uaq);
    expect(uaq.toGregorian(1446, 8, 30), uaq.toGregorian(1446, 9, 1));
  });

  test('an adjustment shifts the Gregorian result by whole days', () {
    final uaq = factory.create(CalendarMethod.uaq);
    expect(
      uaq.toGregorian(1446, 8, 15, adjustment: 1),
      DateTime(2025, 2, 15),
    );
    expect(
      uaq.toGregorian(1446, 8, 15, adjustment: -1),
      DateTime(2025, 2, 13),
    );
  });
}
