import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit_plus/islamic_kit_plus.dart';

void main() {
  group('BundledCityGeocoder (curated, zero-dependency)', () {
    final geocoder = BundledCityGeocoder();

    test('resolves London, GB', () {
      final city = geocoder.resolve('London', country: 'GB');
      expect(city, isNotNull);
      expect(city!.coordinates.latitude, closeTo(51.5, 0.1));
      expect(city.country, 'GB');
    });

    test('resolves a free-text address by segment', () {
      final city = geocoder.resolve('Trafalgar Square, London, UK');
      expect(city?.name, 'London');
    });

    test('country name alias works', () {
      final city = geocoder.resolve('Cairo', country: 'Egypt');
      expect(city?.country, 'EG');
    });
  });

  group('SqliteCityGeocoder (bundled city database)', () {
    late SqliteCityGeocoder geocoder;

    setUpAll(() {
      geocoder = SqliteCityGeocoder.openFile('assets/prayer_times.db');
    });

    tearDownAll(() => geocoder.dispose());

    test('resolves London, GB with Arabic name', () {
      final city = geocoder.resolve('London', country: 'GB');
      expect(city, isNotNull);
      expect(city!.coordinates.latitude, closeTo(51.50853, 0.01));
      expect(city.coordinates.longitude, closeTo(-0.12574, 0.01));
      expect(city.nameAr, isNotNull);
      expect(city.country, 'GB');
    });

    test('resolves Mecca', () {
      final city = geocoder.resolve('Mecca');
      expect(city, isNotNull);
      expect(city!.coordinates.latitude, closeTo(21.42, 0.2));
    });

    test('country name alias resolves to an ISO code', () {
      final city = geocoder.resolve('Cairo', country: 'Egypt');
      expect(city?.country, 'EG');
    });

    test('applies half-hour offsets that the hour column truncates', () {
      expect(
        geocoder.resolve('Tehran', country: 'IR')?.utcOffset,
        const Duration(hours: 3, minutes: 30),
      );
      expect(
        geocoder.resolve('Delhi', country: 'IN')?.utcOffset,
        const Duration(hours: 5, minutes: 30),
      );
    });

    test('prefers the capital over same-named lesser settlements', () {
      final city = geocoder.resolve('Paris', country: 'FR');
      expect(city?.coordinates.latitude, closeTo(48.85, 0.2));
    });

    test('unknown country code matches nothing', () {
      expect(geocoder.search('London', country: 'ZZ'), isEmpty);
    });
  });
}
