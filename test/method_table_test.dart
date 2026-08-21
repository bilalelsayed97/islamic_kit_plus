import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit_plus/islamic_kit_plus.dart';

/// The published parameters for every method, asserted as a table so a change
/// to any angle or correction has to be made deliberately.
void main() {
  group('Method parameters', () {
    // fajr angle, isha angle (null when interval), isha interval minutes.
    const expected = <CalculationMethod, (double, double?, int?)>{
      CalculationMethod.karachi: (18, 18, null),
      CalculationMethod.isna: (15, 15, null),
      CalculationMethod.mwl: (18, 17, null),
      CalculationMethod.makkah: (18.5, null, 90),
      CalculationMethod.egypt: (19.5, 17.5, null),
      CalculationMethod.tehran: (17.7, 14, null),
      CalculationMethod.gulf: (19.5, null, 90),
      CalculationMethod.kuwait: (18, 17.5, null),
      CalculationMethod.qatar: (18, null, 90),
      CalculationMethod.singapore: (20, 18, null),
      CalculationMethod.france: (12, 12, null),
      CalculationMethod.turkey: (18, 17, null),
      CalculationMethod.russia: (16, 15, null),
      CalculationMethod.moonsighting: (18, 18, null),
      CalculationMethod.dubai: (18.2, 18.2, null),
      CalculationMethod.jakim: (20, 18, null),
      CalculationMethod.tunisia: (18, 18, null),
      CalculationMethod.algeria: (18, 17, null),
      CalculationMethod.kemenag: (20, 18, null),
      CalculationMethod.morocco: (18, 17, null),
      CalculationMethod.portugal: (18, null, 77),
      CalculationMethod.jordan: (18.5, null, 90),
      CalculationMethod.oman: (18.5, null, 90),
      CalculationMethod.munich: (18, 17, null),
      CalculationMethod.maldives: (18, 17, null),
      CalculationMethod.canada: (15, 15, null),
      CalculationMethod.tajikistan: (18, 17, null),
      CalculationMethod.vienna: (18, 17, null),
      CalculationMethod.belgium: (18, 17, null),
      CalculationMethod.sudan: (19.5, 17.5, null),
      CalculationMethod.libya: (19.5, 17.5, null),
      CalculationMethod.iraq: (18, 17, null),
      CalculationMethod.luxembourg: (18, 17, null),
      CalculationMethod.custom: (15, 15, null),
    };

    test('covers every method', () {
      expect(expected.keys.toSet(), CalculationMethod.values.toSet());
    });

    expected.forEach((method, values) {
      final (fajr, isha, interval) = values;
      test('${method.code} is $fajr° / ${isha ?? '$interval min'}', () {
        expect(method.params.fajrAngle, fajr);
        expect(method.params.ishaAngle, isha);
        expect(method.params.ishaMinutesAfterMaghrib, interval);
      });
    });
  });

  group('Method corrections', () {
    test('the authorities that publish Dhuhr a minute late', () {
      const plusOne = <CalculationMethod>{
        CalculationMethod.karachi,
        CalculationMethod.isna,
        CalculationMethod.mwl,
        CalculationMethod.egypt,
        CalculationMethod.singapore,
      };
      for (final method in plusOne) {
        expect(method.params.adjustments.dhuhr, 1, reason: method.code);
      }
    });

    test('Dubai shifts sunrise, Dhuhr, Asr and Maghrib', () {
      const a = CalculationMethod.dubai;
      expect(a.params.adjustments.sunrise, -3);
      expect(a.params.adjustments.dhuhr, 3);
      expect(a.params.adjustments.asr, 3);
      expect(a.params.adjustments.maghrib, 3);
    });

    test('Moonsighting shifts Dhuhr +5 and Maghrib +3', () {
      const a = CalculationMethod.moonsighting;
      expect(a.params.adjustments.dhuhr, 5);
      expect(a.params.adjustments.maghrib, 3);
    });

    test('Canada is not an alias of ISNA — it applies no corrections', () {
      expect(CalculationMethod.canada.params.adjustments.isEmpty, isTrue);
      expect(CalculationMethod.isna.params.adjustments.isEmpty, isFalse);
    });

    test('only Umm al-Qura varies its Isha interval in Ramadan', () {
      final varying = CalculationMethod.values
          .where((m) => m.params.hasRamadanIshaInterval)
          .toList();
      expect(varying, <CalculationMethod>[CalculationMethod.makkah]);
      expect(
        CalculationMethod.makkah.params.ramadanIshaMinutesAfterMaghrib,
        120,
      );
    });
  });

  group('Method ids', () {
    test('are unique', () {
      final ids = CalculationMethod.values.map((m) => m.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('aladhan-numbered methods stay at their published id', () {
      expect(CalculationMethod.fromId(1), CalculationMethod.karachi);
      expect(CalculationMethod.fromId(3), CalculationMethod.mwl);
      expect(CalculationMethod.fromId(4), CalculationMethod.makkah);
      expect(CalculationMethod.fromId(23), CalculationMethod.jordan);
      expect(CalculationMethod.fromId(99), CalculationMethod.custom);
    });

    test('package-only methods are numbered from 101', () {
      final extra =
          CalculationMethod.values.where((m) => !m.isAladhanMethod).toList();
      expect(extra, hasLength(11));
      expect(extra.every((m) => m.id >= 101), isTrue);
    });

    test('an unknown id falls back to MWL', () {
      expect(CalculationMethod.fromId(-1), CalculationMethod.mwl);
      expect(CalculationMethod.fromCode('NOPE'), CalculationMethod.mwl);
    });
  });

  group('Bundled database method map', () {
    test('database ids resolve to their own authority, not aladhan\'s', () {
      const cases = <int, CalculationMethod>{
        1: CalculationMethod.karachi,
        2: CalculationMethod.isna,
        3: CalculationMethod.mwl,
        4: CalculationMethod.makkah,
        5: CalculationMethod.egypt,
        6: CalculationMethod.dubai,
        7: CalculationMethod.kuwait,
        8: CalculationMethod.qatar,
        9: CalculationMethod.singapore,
        17: CalculationMethod.oman,
        20: CalculationMethod.canada,
        28: CalculationMethod.tehran,
      };
      cases.forEach((id, method) {
        expect(BundledMethodMap.methodForBundledId(id), method, reason: '$id');
      });
    });

    test('covers a contiguous 1..30 range', () {
      expect(
        BundledMethodMap.knownIds.toSet(),
        List<int>.generate(30, (i) => i + 1).toSet(),
      );
    });

    test('an unknown id has no method, but a defaulted one is MWL', () {
      expect(BundledMethodMap.methodForBundledId(999), isNull);
      expect(BundledMethodMap.methodForBundledId(null), isNull);
      expect(
        BundledMethodMap.methodForBundledIdOrDefault(999),
        CalculationMethod.mwl,
      );
    });
  });
}
