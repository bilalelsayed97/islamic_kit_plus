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

  group('SqliteCityGeocoder (bundled 138k-city database)', () {
    late SqliteCityGeocoder geocoder;

    setUpAll(() {
      geocoder = SqliteCityGeocoder.openFile('assets/NewCountries.sqlite');
    });

    tearDownAll(() => geocoder.dispose());

    test('resolves London, GB with Arabic name', () {
      final city = geocoder.resolve('London', country: 'GB');
      expect(city, isNotNull);
      expect(city!.coordinates.latitude, closeTo(51.50853, 0.01));
      expect(city.coordinates.longitude, closeTo(-0.12574, 0.01));
      expect(city.nameAr, isNotNull);
    });

    test('resolves Mecca', () {
      final city = geocoder.resolve('Mecca');
      expect(city, isNotNull);
      expect(city!.coordinates.latitude, closeTo(21.42, 0.2));
    });
  });
}
