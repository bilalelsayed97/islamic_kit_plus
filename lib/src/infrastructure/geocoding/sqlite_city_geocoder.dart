import 'dart:io';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

import '../../domain/models/city.dart';
import '../../domain/ports/geocoder.dart';
import '../../domain/value_objects/coordinates.dart';
import 'data/city_dataset.dart' show kCountryAliases;

/// [Geocoder] backed by the bundled `NewCountries.sqlite` (≈138k cities with
/// English + Arabic names). Queries are synchronous (sqlite3 is an FFI API);
/// only opening the database is asynchronous — see [openBytes] and the Flutter
/// asset loader.
class SqliteCityGeocoder extends Geocoder {
  SqliteCityGeocoder(this._db);

  final Database _db;

  /// Opens a database from a file [path] (VM / desktop / tests).
  factory SqliteCityGeocoder.openFile(String path) =>
      SqliteCityGeocoder(sqlite3.open(path));

  /// Opens a database from in-memory [bytes] by materializing a cached temp
  /// file (sqlite3 opens by path). Reuses the temp file across calls.
  static Future<SqliteCityGeocoder> openBytes(
    Uint8List bytes, {
    String fileName = 'islamic_kit_plus_cities.sqlite',
  }) async {
    final file = File('${Directory.systemTemp.path}/$fileName');
    if (!file.existsSync() || file.lengthSync() != bytes.length) {
      await file.writeAsBytes(bytes, flush: true);
    }
    return SqliteCityGeocoder.openFile(file.path);
  }

  @override
  List<City> search(String query, {String? country, String? state}) {
    final candidates = _candidates(query);
    if (candidates.isEmpty) return const <City>[];

    final iso = _resolveCountry(country);
    final where = StringBuffer(
      'CityLatitude IS NOT NULL AND (CityNameEn LIKE ? OR CityNameAr LIKE ?)',
    );
    final args = <Object?>['%${candidates.first}%', '%${candidates.first}%'];
    if (iso != null) {
      where.write(' AND UPPER(CountryIso) = ?');
      args.add(iso);
    }
    if (state != null) {
      where.write(' AND (admin1 LIKE ? OR admin2 LIKE ?)');
      args
        ..add('%$state%')
        ..add('%$state%');
    }

    final rows = _db.select(
      'SELECT CityNameEn, CityNameAr, CityLatitude, CityLongitude, '
      'CityZone, CountryIso, admin1 FROM ModifiedCities WHERE $where LIMIT 200',
      args,
    );

    final scored = <({City city, int score})>[];
    for (final row in rows) {
      final en = (row['CityNameEn'] as String?)?.trim() ?? '';
      final ar = (row['CityNameAr'] as String?)?.trim();
      final score = _score(_normalize(en), candidates) ??
          (ar != null ? _score(_normalize(ar), candidates) : null);
      if (score == null) continue;
      scored.add((city: _toCity(row, en, ar), score: score));
    }
    scored.sort((a, b) => a.score.compareTo(b.score));
    return <City>[for (final s in scored) s.city];
  }

  /// Closes the underlying database.
  void dispose() => _db.dispose();

  City _toCity(Row row, String en, String? ar) {
    final zone = (row['CityZone'] as num?)?.toDouble() ?? 0;
    return City(
      name: en,
      nameAr: ar == null || ar.isEmpty ? null : ar,
      country: (row['CountryIso'] as String?)?.toUpperCase() ?? '',
      state: row['admin1'] as String?,
      coordinates: Coordinates(
        (row['CityLatitude'] as num).toDouble(),
        (row['CityLongitude'] as num).toDouble(),
      ),
      utcOffset: Duration(minutes: (zone * 60).round()),
    );
  }

  int? _score(String name, List<String> candidates) {
    int? best;
    for (final c in candidates) {
      int? s;
      if (name == c) {
        s = 0;
      } else if (name.startsWith(c)) {
        s = 1;
      } else if (c.contains(name)) {
        s = 2;
      } else if (name.contains(c)) {
        s = 3;
      }
      if (s != null && (best == null || s < best)) best = s;
    }
    return best;
  }

  List<String> _candidates(String query) {
    final full = _normalize(query);
    if (full.isEmpty) return const <String>[];
    final parts = <String>[full];
    for (final seg in query.split(',')) {
      final n = _normalize(seg);
      if (n.isNotEmpty && !parts.contains(n)) parts.add(n);
    }
    return parts;
  }

  String? _resolveCountry(String? country) {
    if (country == null) return null;
    final normalized = _normalize(country);
    if (normalized.length == 2) return normalized.toUpperCase();
    return kCountryAliases[normalized]?.toUpperCase() ??
        normalized.toUpperCase();
  }

  String _normalize(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
