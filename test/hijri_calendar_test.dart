import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit_plus/islamic_kit_plus.dart';

void main() {
  const factory = HijriConverterFactory();

  group('Gregorian -> Hijri for 14-02-2025', () {
    final date = DateTime(2025, 2, 14);

    test('Umm al-Qura -> 15 Shaban 1446 (29-day month)', () {
      final h = factory.create(CalendarMethod.uaq).fromGregorian(date);
      expect(h.year, 1446);
      expect(h.month, 8);
      expect(h.day, 15);
      expect(h.monthLength, 29);
    });

    test('HJCoSA matches Umm al-Qura when unadjusted', () {
      final h = factory.create(CalendarMethod.hjcosa).fromGregorian(date);
      expect((h.year, h.month, h.day), (1446, 8, 15));
    });

    test('Diyanet -> 16 Shaban 1446 (30-day month)', () {
      final h = factory.create(CalendarMethod.diyanet).fromGregorian(date);
      expect((h.year, h.month, h.day), (1446, 8, 16));
      expect(h.monthLength, 30);
    });

    test('Mathematical -> 15 Shaban 1446 (month length hardcoded 30)', () {
      final h = factory.create(CalendarMethod.mathematical).fromGregorian(date);
      expect((h.year, h.month, h.day), (1446, 8, 15));
      expect(h.monthLength, 30);
    });

    test('Mathematical honours +1 adjustment', () {
      final h = factory
          .create(CalendarMethod.mathematical)
          .fromGregorian(date, adjustment: 1);
      expect(h.day, 16);
    });
  });

  group('Hijri -> Gregorian round trips', () {
    test('Umm al-Qura 15-08-1446 -> 14-02-2025', () {
      final g = factory.create(CalendarMethod.uaq).toGregorian(1446, 8, 15);
      expect((g.year, g.month, g.day), (2025, 2, 14));
    });

    test('Mathematical 15-08-1446 with -1 adjustment -> 13-02-2025', () {
      final g = factory
          .create(CalendarMethod.mathematical)
          .toGregorian(1446, 8, 15, adjustment: -1);
      expect((g.year, g.month, g.day), (2025, 2, 13));
    });
  });

  group('HJCoSA lunar-sighting overrides', () {
    test('17-05-2018 -> 1 Ramadan 1439', () {
      final h = factory
          .create(CalendarMethod.hjcosa)
          .fromGregorian(DateTime(2018, 5, 17));
      expect((h.year, h.month, h.day), (1439, 9, 1));
    });

    test('1 Ramadan 1439 -> 17-05-2018', () {
      final g = factory.create(CalendarMethod.hjcosa).toGregorian(1439, 9, 1);
      expect((g.year, g.month, g.day), (2018, 5, 17));
    });
  });

  group('Validity ranges throw', () {
    test('Umm al-Qura before range', () {
      expect(
        () => factory.create(CalendarMethod.uaq).toGregorian(1200, 8, 15),
        throwsArgumentError,
      );
    });

    test('Umm al-Qura Gregorian before range', () {
      expect(
        () => factory
            .create(CalendarMethod.uaq)
            .fromGregorian(DateTime(1800, 1, 1)),
        throwsArgumentError,
      );
    });
  });
}
