import 'package:flutter/services.dart' show rootBundle;

import 'sqlite_city_geocoder.dart';

/// Path to the bundled city database, as seen from a consuming app.
const String kBundledCityDatabaseAsset =
    'packages/islamic_kit_plus/assets/NewCountries.sqlite';

/// Loads the bundled 138k-city SQLite database and returns a ready
/// [SqliteCityGeocoder]. Call once (e.g. at app start) and pass the result to
/// `PrayerTimesService(geocoder: ...)`.
///
/// Requires a Flutter binding (uses `rootBundle`). On the Dart VM / CLI use
/// [SqliteCityGeocoder.openFile] with a filesystem path instead.
Future<SqliteCityGeocoder> loadBundledCityGeocoder() async {
  final data = await rootBundle.load(kBundledCityDatabaseAsset);
  return SqliteCityGeocoder.openBytes(data.buffer.asUint8List());
}
