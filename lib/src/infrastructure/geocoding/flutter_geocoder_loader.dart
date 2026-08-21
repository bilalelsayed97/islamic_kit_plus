import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

import 'city_directory.dart';
import 'sqlite_city_geocoder.dart';

/// Path to the bundled city database, as seen from a consuming app.
const String kBundledCityDatabaseAsset =
    'packages/islamic_kit_plus/assets/prayer_times.db';

/// Marker bumped whenever the bundled database's contents change.
///
/// It is part of the materialized file's name, so a shipped update lands under
/// a new path instead of silently reusing the previous release's copy.
const String kBundledCityDatabaseVersion = '2';

/// Copies the bundled database out of the asset bundle and returns its path,
/// reusing the copy from a previous launch when one is already present.
///
/// The asset is tens of megabytes, so the existence check runs *before*
/// `rootBundle.load`: on every launch after the first, nothing is read into
/// memory and nothing is written to disk.
///
/// Pass [directory] to control where the copy lives — on mobile the system temp
/// directory can be reclaimed by the OS, so an application-support directory is
/// the durable choice.
Future<String> materializeBundledCityDatabase({Directory? directory}) async {
  final dir = directory ?? Directory.systemTemp;
  final file = File(
    '${dir.path}/islamic_kit_plus_prayer_times_v$kBundledCityDatabaseVersion.db',
  );
  if (file.existsSync() && file.lengthSync() > 0) return file.path;

  final data = await rootBundle.load(kBundledCityDatabaseAsset);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    flush: true,
  );
  return file.path;
}

/// Loads the bundled city database and returns a ready [SqliteCityGeocoder].
///
/// Call once (e.g. at app start) and pass the result to
/// `PrayerTimesService(geocoder: ...)`.
///
/// Requires a Flutter binding (uses `rootBundle`). On the Dart VM / CLI use
/// [SqliteCityGeocoder.openFile] with a filesystem path instead.
Future<SqliteCityGeocoder> loadBundledCityGeocoder({
  Directory? directory,
}) async {
  return SqliteCityGeocoder.openFile(
    await materializeBundledCityDatabase(directory: directory),
  );
}

/// Loads the bundled city database and returns a ready [CityDirectory] for
/// country/city browsing, reverse geocoding and timezone options.
///
/// Requires a Flutter binding (uses `rootBundle`). On the Dart VM / CLI use
/// [CityDirectory.openFile] with a filesystem path instead.
Future<CityDirectory> loadBundledCityDirectory({Directory? directory}) async {
  return CityDirectory.openFile(
    await materializeBundledCityDatabase(directory: directory),
  );
}
