import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit_plus/islamic_kit_plus.dart';

void main() {
  group('LocationDefaults', () {
    test('method by country', () {
      expect(LocationDefaults.methodForCountry('US'), CalculationMethod.isna);
      expect(LocationDefaults.methodForCountry('SA'), CalculationMethod.makkah);
      expect(
          LocationDefaults.methodForCountry('PK'), CalculationMethod.karachi);
      expect(LocationDefaults.methodForCountry('gb'), CalculationMethod.mwl);
      expect(LocationDefaults.methodForCountry('XX'), CalculationMethod.mwl);
    });

    test('school by country', () {
      expect(LocationDefaults.schoolForCountry('PK'), AsrSchool.hanafi);
      expect(LocationDefaults.schoolForCountry('GB'), AsrSchool.standard);
    });
  });

  group('automatic per-location settings', () {
    final service = PrayerTimesService(); // curated geocoder (has Cairo, EG)

    test('recommendedParams picks method + school', () {
      final p =
          service.recommendedParams('EG', utcOffset: const Duration(hours: 2));
      expect(p.method, CalculationMethod.egypt);
      expect(p.school, AsrSchool.standard);
      expect(p.utcOffset, const Duration(hours: 2));
    });

    test('timingsByCityAuto infers method + offset with no presets', () {
      final result = service.timingsByCityAuto(
        'Cairo',
        country: 'EG',
        date: DateTime(2024, 4, 24),
      );
      expect(result.meta.method, CalculationMethod.egypt);
      expect(result.meta.coordinates.latitude, closeTo(30.04, 0.1));
      expect(result.formatted(Prayer.fajr), isNot(invalidTime));
    });
  });
}
