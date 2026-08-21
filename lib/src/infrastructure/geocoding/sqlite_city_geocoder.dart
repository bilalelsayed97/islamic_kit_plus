import 'dart:io';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

import '../../domain/models/city.dart';
import '../../domain/ports/geocoder.dart';
import '../../domain/value_objects/coordinates.dart';
import 'data/city_dataset.dart' show kCountryAliases;
import 'data/country_iso_map.dart';

/// [Geocoder] backed by the bundled `prayer_times.db` (≈131k populated places
/// with English + Arabic names). Queries are synchronous (sqlite3 is an FFI
/// API); only opening the database is asynchronous — see [openBytes] and the
/// Flutter asset loader.
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
    String fileName = 'islamic_kit_plus_prayer_times.db',
  }) async {
    final file = File('${Directory.systemTemp.path}/$fileName');
    if (!file.existsSync() || file.lengthSync() != bytes.length) {
      await file.writeAsBytes(bytes, flush: true);
    }
    return SqliteCityGeocoder.openFile(file.path);
  }

  /// Returns matches for [query], best first.
  ///
  /// [state] is accepted for interface compatibility but ignored: the bundled
  /// database carries no administrative-region column, so [City.state] is
  /// always `null` here.
  @override
  List<City> search(String query, {String? country, String? state}) {
    final candidates = _candidates(query);
    if (candidates.isEmpty) return const <City>[];

    final iso = _resolveCountry(country);
    final where = StringBuffer(
      "city_level LIKE 'PPL%' AND (city_name_en LIKE ? OR city_name_ar LIKE ?)",
    );
    final args = <Object?>['%${candidates.first}%', '%${candidates.first}%'];
    if (iso != null) {
      final countryId = kIsoToCountryId[iso];
      // An unknown country code can match nothing, mirroring the behaviour of
      // filtering on a code that is absent from the database.
      if (countryId == null) return const <City>[];
      where.write(' AND country_id = ?');
      args.add(countryId);
    }

    final rows = _db.select(
      'SELECT city_name_en, city_name_ar, city_latitude, city_longitude, '
      'city_time_zone, time_zone_id, country_id, city_level '
      'FROM prayer_times_city_lookups WHERE $where LIMIT 200',
      args,
    );

    final scored = <({City city, int score, int rank})>[];
    for (final row in rows) {
      final en = (row['city_name_en'] as String?)?.trim() ?? '';
      final ar = (row['city_name_ar'] as String?)?.trim();
      final score = _score(_normalize(en), candidates) ??
          (ar != null ? _score(_normalize(ar), candidates) : null);
      if (score == null) continue;
      scored.add((
        city: _toCity(row, en, ar),
        score: score,
        rank: _placeRank(row['city_level'] as String?),
      ));
    }
    // Equally good name matches are broken by settlement importance, so a
    // capital wins over a same-named village.
    scored.sort((a, b) {
      final byScore = a.score.compareTo(b.score);
      return byScore != 0 ? byScore : a.rank.compareTo(b.rank);
    });
    return <City>[for (final s in scored) s.city];
  }

  /// Closes the underlying database.
  void dispose() => _db.dispose();

  City _toCity(Row row, String en, String? ar) {
    return City(
      name: en,
      nameAr: ar == null || ar.isEmpty ? null : ar,
      country: kCountryIdToIso[row['country_id'] as int?] ?? '',
      state: null,
      coordinates: Coordinates(
        (row['city_latitude'] as num).toDouble(),
        (row['city_longitude'] as num).toDouble(),
      ),
      utcOffset: Duration(
        minutes: _offsetMinutes(
          row['time_zone_id'] as String?,
          row['city_time_zone'] as num?,
        ),
      ),
    );
  }

  /// Standard-time offset in minutes.
  ///
  /// `city_time_zone` holds whole hours truncated toward zero, so zones with a
  /// half- or quarter-hour offset are resolved from their IANA id first and
  /// only fall back to the hour column when the id is missing or unremarkable.
  int _offsetMinutes(String? timeZoneId, num? hours) {
    if (timeZoneId != null && timeZoneId.isNotEmpty) {
      final minutes = kFractionalZoneOffsetMinutes[timeZoneId];
      if (minutes != null) return minutes;
    }
    return ((hours ?? 0) * 60).round();
  }

  /// Orders settlement feature codes by prominence, lowest first.
  int _placeRank(String? level) => switch (level) {
        'PPLC' => 0, // national capital
        'PPLA' => 1, // first-order administrative capital
        'PPLA2' => 2,
        'PPLA3' => 3,
        'PPLA4' => 4,
        'PPL' => 5,
        _ => 6,
      };

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
