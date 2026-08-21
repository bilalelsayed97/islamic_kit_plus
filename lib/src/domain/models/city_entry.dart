import '../value_objects/coordinates.dart';

/// A city row from the bundled city database, with its country resolved.
///
/// This is the richer sibling of [City]: it keeps the database identifiers and
/// both localized name pairs, which a city-picker UI needs and a geocoding
/// result does not.
class CityEntry {
  const CityEntry({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.countryId,
    required this.countryNameEn,
    required this.countryNameAr,
    required this.isoCode,
    required this.coordinates,
    required this.utcOffset,
    this.timeZoneId,
  });

  /// Primary key in the bundled database (`prayer_times_city_lookups`).
  final int id;

  /// English city name.
  final String nameEn;

  /// Arabic city name.
  final String nameAr;

  /// Owning country's primary key.
  final int countryId;

  /// English country name.
  final String countryNameEn;

  /// Arabic country name.
  final String countryNameAr;

  /// ISO 3166-1 alpha-2 code of the owning country. Empty when unmapped.
  final String isoCode;

  final Coordinates coordinates;

  /// IANA timezone identifier, e.g. `"Africa/Cairo"`. `null` when unknown.
  final String? timeZoneId;

  /// Standard-time UTC offset. Does **not** account for daylight saving.
  final Duration utcOffset;

  @override
  bool operator ==(Object other) => other is CityEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CityEntry($nameEn, $isoCode)';
}
