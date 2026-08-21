import 'dart:io';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

import '../../domain/models/city_entry.dart';
import '../../domain/models/country_info.dart';
import '../../domain/models/time_zone_info.dart';
import '../../domain/value_objects/coordinates.dart';
import 'data/country_iso_map.dart';

/// Browsable, localized view over the bundled `prayer_times.db`.
///
/// [SqliteCityGeocoder] answers "which city is this text?"; [CityDirectory]
/// answers the questions a location-picker asks instead — list the countries,
/// page through a country's cities, resolve GPS coordinates to a city, and
/// offer the timezones a country actually spans. Every method reads English and
/// Arabic names together so the caller can render either locale.
///
/// Queries are synchronous (sqlite3 is an FFI API); only opening the database
/// is asynchronous — see [openBytes] and `loadBundledCityDirectory()`.
class CityDirectory {
  CityDirectory(this._db);

  final Database _db;

  /// Opens a database from a file [path] (VM / desktop / tests).
  factory CityDirectory.openFile(String path) =>
      CityDirectory(sqlite3.open(path));

  /// Opens a database from in-memory [bytes] by materializing a cached file
  /// under [directory] (sqlite3 opens by path), reusing it across launches.
  ///
  /// [fileName] should carry a version marker so a shipped database update
  /// lands under a new name instead of colliding with the stale copy.
  static Future<CityDirectory> openBytes(
    Uint8List bytes, {
    String fileName = 'islamic_kit_plus_prayer_times.db',
    Directory? directory,
  }) async {
    final dir = directory ?? Directory.systemTemp;
    final file = File('${dir.path}/$fileName');
    if (!file.existsSync() || file.lengthSync() != bytes.length) {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    }
    return CityDirectory.openFile(file.path);
  }

  /// Every country that has at least one populated place, ordered by English
  /// name. [query] filters on either name, case-insensitively.
  List<CountryInfo> countries({String? query}) {
    final trimmed = query?.trim() ?? '';
    final filtered = trimmed.isNotEmpty;
    final rows = _db.select(
      'SELECT country_id, country_name_en, country_name_ar, calc_method '
      'FROM prayer_times_country_lookups '
      '${filtered ? 'WHERE (country_name_en LIKE ? OR country_name_ar LIKE ?) ' : ''}'
      'ORDER BY country_name_en COLLATE NOCASE',
      filtered ? <Object?>['%$trimmed%', '%$trimmed%'] : const <Object?>[],
    );
    return <CountryInfo>[for (final row in rows) _toCountry(row)];
  }

  /// The country with [countryId], or `null` when no such row exists.
  CountryInfo? country(int countryId) {
    final rows = _db.select(
      'SELECT country_id, country_name_en, country_name_ar, calc_method '
      'FROM prayer_times_country_lookups WHERE country_id = ? LIMIT 1',
      <Object?>[countryId],
    );
    return rows.isEmpty ? null : _toCountry(rows.first);
  }

  /// Populated places inside [countryId], most prominent first.
  ///
  /// Prominence ordering matters here: a country's rows run to five figures and
  /// are dominated by neighbourhoods, so an alphabetical list buries the
  /// capital. [query] filters on either name; [limit] and [offset] page.
  List<CityEntry> citiesInCountry(
    int countryId, {
    String? query,
    int limit = 50,
    int offset = 0,
  }) {
    return _cities(
      where: 'c.country_id = ?',
      args: <Object?>[countryId],
      query: query,
      limit: limit,
      offset: offset,
    );
  }

  /// Populated places anywhere, most prominent first. See [citiesInCountry].
  List<CityEntry> searchCities({
    String? query,
    int limit = 50,
    int offset = 0,
  }) {
    return _cities(
      where: null,
      args: const <Object?>[],
      query: query,
      limit: limit,
      offset: offset,
    );
  }

  /// The city [latitude]/[longitude] most plausibly names.
  ///
  /// Not simply the closest row: the database records neighbourhoods alongside
  /// the cities that contain them, so a plain proximity sort answers "Az
  /// Zamalek" where a person would answer "Cairo". Distance is therefore
  /// weighted by settlement prominence, letting a nearby capital or
  /// administrative seat outrank a marginally closer suburb, and the search
  /// widens only if the initial box is empty.
  CityEntry? nearestCity(double latitude, double longitude) {
    for (final delta in const <double>[0.5, 2.0]) {
      final match = _nearestWithin(latitude, longitude, delta);
      if (match != null) return match;
    }
    return _nearestWithin(latitude, longitude, null);
  }

  /// The timezones [countryId] actually spans, ordered by IANA id.
  ///
  /// Border towns carry a neighbour's zone, which would otherwise present Egypt
  /// as a four-zone country. A zone is included only when it covers at least
  /// 0.5% of the country's populated places, which keeps every genuine zone of
  /// even the most fragmented countries while dropping those strays.
  List<TimeZoneInfo> timeZonesForCountry(int countryId) {
    final rows = _db.select(
      'WITH zone_counts AS ('
      '  SELECT TRIM(time_zone_id) AS zone, COUNT(*) AS n'
      '    FROM prayer_times_city_lookups'
      "   WHERE country_id = ? AND city_level LIKE 'PPL%'"
      "     AND TRIM(COALESCE(time_zone_id, '')) <> ''"
      '   GROUP BY zone)'
      'SELECT z.zone, t.zone_name_ar '
      '  FROM zone_counts z '
      '  LEFT JOIN prayer_times_time_zone_lookups t ON t.time_zone_id = z.zone '
      ' WHERE z.n * 200 >= (SELECT SUM(n) FROM zone_counts) '
      ' ORDER BY z.zone COLLATE NOCASE',
      <Object?>[countryId],
    );
    return <TimeZoneInfo>[
      for (final row in rows)
        TimeZoneInfo(
          ianaId: row['zone'] as String,
          countryId: countryId,
          nameAr: _trimToNull(row['zone_name_ar'] as String?),
        ),
    ];
  }

  /// Closes the underlying database.
  void dispose() => _db.dispose();

  // --- internals -----------------------------------------------------------

  List<CityEntry> _cities({
    required String? where,
    required List<Object?> args,
    required String? query,
    required int limit,
    required int offset,
  }) {
    final trimmed = query?.trim() ?? '';
    final clauses = <String>["c.city_level LIKE 'PPL%'"];
    final bindings = <Object?>[...args];
    if (where != null) clauses.add(where);
    if (trimmed.isNotEmpty) {
      clauses.add('(c.city_name_en LIKE ? OR c.city_name_ar LIKE ?)');
      bindings..add('%$trimmed%')..add('%$trimmed%');
    }

    final rows = _db.select(
      '$_citySelect WHERE ${clauses.join(' AND ')} '
      'ORDER BY $_prominence, c.city_name_en COLLATE NOCASE '
      'LIMIT ? OFFSET ?',
      <Object?>[...bindings, limit, offset],
    );
    return <CityEntry>[for (final row in rows) _toCity(row)];
  }

  CityEntry? _nearestWithin(double latitude, double longitude, double? delta) {
    final clauses = <String>["c.city_level LIKE 'PPL%'"];
    final bindings = <Object?>[];
    if (delta != null) {
      clauses.add('c.city_latitude BETWEEN ? AND ?');
      clauses.add('c.city_longitude BETWEEN ? AND ?');
      bindings
        ..add(latitude - delta)
        ..add(latitude + delta)
        ..add(longitude - delta)
        ..add(longitude + delta);
    }

    final rows = _db.select(
      '$_citySelect WHERE ${clauses.join(' AND ')} '
      'ORDER BY (((c.city_latitude - ?) * (c.city_latitude - ?)) '
      '        + ((c.city_longitude - ?) * (c.city_longitude - ?))) '
      '        * $_prominenceWeight '
      'LIMIT 1',
      <Object?>[...bindings, latitude, latitude, longitude, longitude],
    );
    return rows.isEmpty ? null : _toCity(rows.first);
  }

  static const String _citySelect =
      'SELECT c.city_id, c.city_name_en, c.city_name_ar, c.country_id, '
      'c.city_latitude, c.city_longitude, c.city_time_zone, c.time_zone_id, '
      'c.city_level, co.country_name_en, co.country_name_ar '
      'FROM prayer_times_city_lookups c '
      'LEFT JOIN prayer_times_country_lookups co '
      '  ON co.country_id = c.country_id';

  /// Settlement prominence as a sort key, most prominent first.
  static const String _prominence = "CASE c.city_level "
      "WHEN 'PPLC' THEN 0 WHEN 'PPLA' THEN 1 WHEN 'PPLA2' THEN 2 "
      "WHEN 'PPLA3' THEN 3 WHEN 'PPLA4' THEN 4 WHEN 'PPL' THEN 5 ELSE 6 END";

  /// Distance multiplier that lets a prominent place outrank a closer suburb.
  static const String _prominenceWeight = "CASE c.city_level "
      "WHEN 'PPLC' THEN 1.0 WHEN 'PPLA' THEN 1.0 WHEN 'PPLA2' THEN 1.5 "
      "WHEN 'PPLA3' THEN 2.0 WHEN 'PPLA4' THEN 2.5 ELSE 3.0 END";

  CountryInfo _toCountry(Row row) {
    final id = row['country_id'] as int;
    return CountryInfo(
      id: id,
      nameEn: (row['country_name_en'] as String?)?.trim() ?? '',
      nameAr: (row['country_name_ar'] as String?)?.trim() ?? '',
      isoCode: kCountryIdToIso[id] ?? '',
      calculationMethod: (row['calc_method'] as num?)?.toInt(),
    );
  }

  CityEntry _toCity(Row row) {
    final countryId = row['country_id'] as int? ?? 0;
    final timeZoneId = _trimToNull(row['time_zone_id'] as String?);
    return CityEntry(
      id: row['city_id'] as int,
      nameEn: (row['city_name_en'] as String?)?.trim() ?? '',
      nameAr: (row['city_name_ar'] as String?)?.trim() ?? '',
      countryId: countryId,
      countryNameEn: (row['country_name_en'] as String?)?.trim() ?? '',
      countryNameAr: (row['country_name_ar'] as String?)?.trim() ?? '',
      isoCode: kCountryIdToIso[countryId] ?? '',
      coordinates: Coordinates(
        (row['city_latitude'] as num).toDouble(),
        (row['city_longitude'] as num).toDouble(),
      ),
      timeZoneId: timeZoneId,
      utcOffset: Duration(
        minutes: _offsetMinutes(timeZoneId, row['city_time_zone'] as num?),
      ),
    );
  }

  /// Standard-time offset in minutes; mirrors [SqliteCityGeocoder].
  int _offsetMinutes(String? timeZoneId, num? hours) {
    if (timeZoneId != null && timeZoneId.isNotEmpty) {
      final minutes = kFractionalZoneOffsetMinutes[timeZoneId];
      if (minutes != null) return minutes;
    }
    return ((hours ?? 0) * 60).round();
  }

  String? _trimToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
