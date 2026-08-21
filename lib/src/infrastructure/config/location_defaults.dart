import '../../domain/enums/asr_school.dart';
import '../../domain/enums/calculation_method.dart';

/// Recommended calculation defaults per country, keyed by ISO-3166 alpha-2
/// code. Countries not listed fall back to the Muslim World League method,
/// which is the common default across Europe and much of the world.
///
/// This is the fallback for when the bundled city database is not open. When
/// it is, prefer the database's own `calc_method` column — see
/// `BundledMethodMap` and `PrayerTimesService.autoParamsForCoordinates`; it
/// covers all 251 countries rather than the subset listed here, and the two
/// agree wherever both have an opinion.
class LocationDefaults {
  const LocationDefaults._();

  static const Map<String, CalculationMethod> _methodByCountry =
      <String, CalculationMethod>{
    // North America
    'US': CalculationMethod.isna,
    'CA': CalculationMethod.canada,
    'MX': CalculationMethod.isna,
    // Gulf / Arabian Peninsula
    'SA': CalculationMethod.makkah,
    'AE': CalculationMethod.dubai,
    'KW': CalculationMethod.kuwait,
    'QA': CalculationMethod.qatar,
    'BH': CalculationMethod.makkah,
    'OM': CalculationMethod.oman,
    'YE': CalculationMethod.makkah,
    // Levant / North & East Africa
    'EG': CalculationMethod.egypt,
    'NG': CalculationMethod.egypt,
    'SD': CalculationMethod.sudan,
    'SS': CalculationMethod.sudan,
    'SY': CalculationMethod.makkah,
    'IQ': CalculationMethod.iraq,
    'LY': CalculationMethod.libya,
    'JO': CalculationMethod.jordan,
    'DZ': CalculationMethod.algeria,
    'MA': CalculationMethod.morocco,
    'EH': CalculationMethod.morocco,
    'TN': CalculationMethod.tunisia,
    // Iran / Turkey / Russia / Central Asia
    'IR': CalculationMethod.tehran,
    'TR': CalculationMethod.turkey,
    'RU': CalculationMethod.russia,
    'TJ': CalculationMethod.tajikistan,
    // South Asia
    'PK': CalculationMethod.karachi,
    'IN': CalculationMethod.karachi,
    'BD': CalculationMethod.karachi,
    'AF': CalculationMethod.karachi,
    'MV': CalculationMethod.maldives,
    // South-East Asia
    'ID': CalculationMethod.singapore,
    'MY': CalculationMethod.singapore,
    'SG': CalculationMethod.singapore,
    'BN': CalculationMethod.jakim,
    'VN': CalculationMethod.makkah,
    // Europe with dedicated authorities
    'FR': CalculationMethod.france,
    'MF': CalculationMethod.france,
    'PT': CalculationMethod.portugal,
    'DE': CalculationMethod.munich,
    'AT': CalculationMethod.vienna,
    'BE': CalculationMethod.belgium,
    'LU': CalculationMethod.luxembourg,
  };

  /// Countries where the Hanafi Asr shadow (factor 2) is the common default.
  static const Set<String> _hanafiDefault = <String>{
    'PK',
    'IN',
    'BD',
    'AF',
    'TR',
  };

  /// The recommended [CalculationMethod] for [countryCode] (falls back to MWL).
  static CalculationMethod methodForCountry(String countryCode) =>
      _methodByCountry[countryCode.toUpperCase()] ?? CalculationMethod.mwl;

  /// The recommended [AsrSchool] for [countryCode] (falls back to Standard).
  static AsrSchool schoolForCountry(String countryCode) =>
      _hanafiDefault.contains(countryCode.toUpperCase())
          ? AsrSchool.hanafi
          : AsrSchool.standard;
}
