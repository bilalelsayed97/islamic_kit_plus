import '../value_objects/coordinates.dart';

/// A geocoded city from the bundled dataset (or a custom [Geocoder]).
class City {
  const City({
    required this.name,
    required this.country,
    required this.coordinates,
    required this.utcOffset,
    this.nameAr,
    this.state,
  });

  final String name;

  /// Arabic city name, if known (from the bundled database).
  final String? nameAr;

  /// ISO 3166-1 alpha-2 country code, e.g. `"GB"`.
  final String country;

  /// Administrative region / state, if known.
  final String? state;

  final Coordinates coordinates;

  /// Standard-time UTC offset for the city (does **not** account for DST;
  /// override per-date if you need DST-correct results).
  final Duration utcOffset;

  @override
  String toString() =>
      'City($name${state != null ? ', $state' : ''}, $country)';
}
