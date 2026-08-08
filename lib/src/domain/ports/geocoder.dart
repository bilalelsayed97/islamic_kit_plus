import '../models/city.dart';

/// Resolves free-text locations (addresses / city names) to coordinates.
///
/// The default [BundledCityGeocoder] uses an offline dataset, but any
/// implementation can be injected (Dependency Inversion) — including one that
/// wraps an online service in an app that allows network access.
abstract class Geocoder {
  /// Returns all matches for [query], optionally filtered by [country]
  /// (ISO-3166 alpha-2) and [state]. Ordered best-match first.
  List<City> search(String query, {String? country, String? state});

  /// The single best match for [query], or `null` if none.
  City? resolve(String query, {String? country, String? state}) {
    final matches = search(query, country: country, state: state);
    return matches.isEmpty ? null : matches.first;
  }
}
