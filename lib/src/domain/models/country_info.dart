/// A country row from the bundled city database.
///
/// Country names ship in both English and Arabic, so a caller can render the
/// active locale without a second lookup.
class CountryInfo {
  const CountryInfo({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.isoCode,
    this.calculationMethodId,
  });

  /// Primary key in the bundled database (`prayer_times_country_lookups`).
  final int id;

  /// English country name, e.g. `"Egypt"`.
  final String nameEn;

  /// Arabic country name, e.g. `"مصر"`.
  final String nameAr;

  /// ISO 3166-1 alpha-2 code, e.g. `"EG"`. Empty when the id is unmapped.
  final String isoCode;

  /// Raw `calc_method` value the database recommends for this country.
  ///
  /// This is the database's own numbering, **not** an aladhan method id — the
  /// two collide above 5. Resolve it with `BundledMethodMap` (or the
  /// `calculationMethod` extension getter) rather than interpreting it.
  final int? calculationMethodId;

  @override
  bool operator ==(Object other) => other is CountryInfo && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CountryInfo($nameEn, $isoCode)';
}
