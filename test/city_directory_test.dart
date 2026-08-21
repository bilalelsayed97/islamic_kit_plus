import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit_plus/islamic_kit_plus.dart';

void main() {
  group('CityDirectory (bundled city database)', () {
    late CityDirectory directory;

    setUpAll(() {
      directory = CityDirectory.openFile('assets/prayer_times.db');
    });

    tearDownAll(() => directory.dispose());

    test('lists every country with an ISO code and both names', () {
      final countries = directory.countries();
      expect(countries.length, 251);
      expect(countries.every((c) => c.isoCode.length == 2), isTrue);
      expect(countries.every((c) => c.nameEn.isNotEmpty), isTrue);
      expect(countries.every((c) => c.nameAr.isNotEmpty), isTrue);
    });

    test('filters countries by either language', () {
      expect(directory.countries(query: 'Egypt').single.isoCode, 'EG');
      expect(directory.countries(query: 'مصر').single.isoCode, 'EG');
    });

    test('exposes the recommended calculation method', () {
      final egypt = directory.countries(query: 'Egypt').single;
      expect(egypt.calculationMethodId, 5);
      expect(egypt.calculationMethod, CalculationMethod.egypt);
    });

    test('resolves the database method ids that collide with aladhan ids', () {
      CalculationMethod? methodFor(String iso) =>
          directory.country(kIsoToCountryId[iso]!)!.calculationMethod;

      // The database numbers its authorities independently of aladhan: id 7 is
      // Kuwait here but Tehran there, id 9 is Singapore here but Kuwait there.
      expect(methodFor('KW'), CalculationMethod.kuwait);
      expect(methodFor('QA'), CalculationMethod.qatar);
      expect(methodFor('SG'), CalculationMethod.singapore);
      expect(methodFor('SA'), CalculationMethod.makkah);
      expect(methodFor('TR'), CalculationMethod.turkey);
      expect(methodFor('CA'), CalculationMethod.canada);
      expect(methodFor('IR'), CalculationMethod.tehran);
      expect(methodFor('OM'), CalculationMethod.oman);
      expect(methodFor('DE'), CalculationMethod.munich);
      expect(methodFor('LU'), CalculationMethod.luxembourg);
      // The default bucket the database assigns to most of the world.
      expect(methodFor('GB'), CalculationMethod.mwl);
    });

    test('every country resolves to a known method', () {
      final unresolved = directory
          .countries()
          .where((c) => c.calculationMethod == null)
          .toList();
      expect(unresolved, isEmpty);
    });

    test('cities carry their country\'s recommended method', () {
      final mecca = directory.nearestCity(21.4225, 39.8262);
      expect(mecca?.calculationMethod, CalculationMethod.makkah);
    });

    test('orders a country\'s cities by prominence, capital first', () {
      final egypt = directory.countries(query: 'Egypt').single;
      final cities = directory.citiesInCountry(egypt.id, limit: 1);
      expect(cities.single.nameEn, 'Cairo');
      expect(cities.single.nameAr, 'القاهرة');
      expect(cities.single.isoCode, 'EG');
    });

    test('pages through a country\'s cities without repeating', () {
      final egypt = directory.countries(query: 'Egypt').single;
      final first = directory.citiesInCountry(egypt.id, limit: 10);
      final second = directory.citiesInCountry(egypt.id, limit: 10, offset: 10);
      expect(first, hasLength(10));
      expect(second, hasLength(10));
      expect(first.toSet().intersection(second.toSet()), isEmpty);
    });

    test('search matches Arabic and English names', () {
      expect(
        directory.searchCities(query: 'القاهرة', limit: 1).single.nameEn,
        'Cairo',
      );
      expect(
        directory.searchCities(query: 'Cairo', limit: 1).single.nameAr,
        'القاهرة',
      );
    });

    test('reverse geocoding answers the city, not the neighbourhood', () {
      final city = directory.nearestCity(30.06263, 31.24967);
      expect(city?.nameEn, 'Cairo');
      expect(city?.isoCode, 'EG');
      expect(city?.timeZoneId, 'Africa/Cairo');
    });

    test('reverse geocoding resolves Mecca', () {
      final city = directory.nearestCity(21.4225, 39.8262);
      expect(city?.nameAr, 'مكة المكرمة');
      expect(city?.isoCode, 'SA');
    });

    test('reverse geocoding falls back when the local box is empty', () {
      // Mid-Atlantic: no populated place for thousands of kilometres.
      expect(directory.nearestCity(0, -30), isNotNull);
    });

    test('single-zone countries offer exactly one timezone', () {
      final egypt = directory.countries(query: 'Egypt').single;
      final zones = directory.timeZonesForCountry(egypt.id);
      expect(zones, hasLength(1));
      expect(zones.single.ianaId, 'Africa/Cairo');
      expect(zones.single.nameAr, isNotEmpty);
    });

    test('multi-zone countries offer every real zone', () {
      final us = directory
          .countries(query: 'United States')
          .firstWhere((c) => c.isoCode == 'US');
      final zones = directory.timeZonesForCountry(us.id);
      expect(zones.length, greaterThanOrEqualTo(8));
      expect(
        zones.map((z) => z.ianaId),
        containsAll(<String>['America/New_York', 'America/Los_Angeles']),
      );
    });

    test('every offered timezone carries an Arabic label', () {
      for (final country in directory.countries()) {
        for (final zone in directory.timeZonesForCountry(country.id)) {
          expect(zone.nameAr, isNotNull, reason: zone.ianaId);
        }
      }
    });

    test('ISO map round-trips in both directions', () {
      expect(kCountryIdToIso.length, 251);
      expect(kIsoToCountryId['EG'], isNotNull);
      expect(kCountryIdToIso[kIsoToCountryId['EG']!], 'EG');
    });
  });
}
