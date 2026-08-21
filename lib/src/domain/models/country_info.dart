/// A country row from the bundled city database.
///
/// Country names ship in both English and Arabic, so a caller can render the
/// active locale without a second lookup. [calculationMethod] is the
/// aladhan.com method id the database recommends for the country; it is `null`
/// when the database records no preference.
class CountryInfo {
  const CountryInfo({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.isoCode,
    this.calculationMethod,
  });

  /// Primary key in the bundled database (`prayer_times_country_lookups`).
  final int id;

  /// English country name, e.g. `"Egypt"`.
  final String nameEn;

  /// Arabic country name, e.g. `"مصر"`.
  final String nameAr;

  /// ISO 3166-1 alpha-2 code, e.g. `"EG"`. Empty when the id is unmapped.
  final String isoCode;

  /// aladhan.com calculation-method id recommended for this country.
  final int? calculationMethod;

  @override
  bool operator ==(Object other) => other is CountryInfo && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CountryInfo($nameEn, $isoCode)';
}
