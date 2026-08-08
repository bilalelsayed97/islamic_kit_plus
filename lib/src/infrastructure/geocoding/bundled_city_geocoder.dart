import '../../domain/models/city.dart';
import '../../domain/ports/geocoder.dart';
import '../../domain/value_objects/coordinates.dart';
import 'data/city_dataset.dart';

/// Offline [Geocoder] backed by the bundled [kCityDataset].
///
/// Matching is name-based: exact, prefix, then substring, best-first. For
/// free-text addresses it also tries each comma-separated segment, so
/// `"Trafalgar Square, London, UK"` still resolves to London.
class BundledCityGeocoder extends Geocoder {
  BundledCityGeocoder([List<CityRecord>? cities])
      : _cities = cities ?? kCityDataset;

  final List<CityRecord> _cities;

  @override
  List<City> search(String query, {String? country, String? state}) {
    final candidates = _candidates(query);
    if (candidates.isEmpty) return const <City>[];

    final countryCode = _resolveCountry(country);
    final normState = state == null ? null : _normalize(state);

    final scored = <({City city, int score})>[];
    for (final record in _cities) {
      if (countryCode != null && record.country.toUpperCase() != countryCode) {
        continue;
      }
      if (normState != null &&
          (record.state == null || _normalize(record.state!) != normState)) {
        continue;
      }
      final score = _score(_normalize(record.name), candidates);
      if (score != null) scored.add((city: _toCity(record), score: score));
    }

    scored.sort((a, b) => a.score.compareTo(b.score));
    return <City>[for (final s in scored) s.city];
  }

  /// Best (lowest) match score of [name] against any candidate, or null.
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

  City _toCity(CityRecord r) => City(
        name: r.name,
        country: r.country,
        state: r.state,
        coordinates: Coordinates(r.lat, r.lng),
        utcOffset: Duration(minutes: r.offsetMinutes),
      );
}
