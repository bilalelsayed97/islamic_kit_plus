/// Flutter entrypoint for islamic_kit_plus.
///
/// Re-exports the full core API plus [loadBundledCityGeocoder], which loads the
/// bundled 138k-city SQLite database via `rootBundle`. Import this (instead of
/// `islamic_kit_plus.dart`) in a Flutter app when you want by-city / by-address
/// lookups backed by the bundled database:
///
/// ```dart
/// final geocoder = await loadBundledCityGeocoder();
/// final service = PrayerTimesService(geocoder: geocoder);
/// ```
library;

export 'islamic_kit_plus.dart';
export 'src/infrastructure/geocoding/flutter_geocoder_loader.dart';
