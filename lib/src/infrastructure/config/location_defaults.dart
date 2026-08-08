import '../../domain/enums/asr_school.dart';
import '../../domain/enums/calculation_method.dart';

/// Recommended calculation defaults per country — the offline equivalent of the
/// aladhan API picking "the closest authority based on location".
///
/// Keyed by ISO-3166 alpha-2 country code. Countries not listed fall back to the
/// Muslim World League method, which is the common default across Europe and
/// much of the world.
class LocationDefaults {
  const LocationDefaults._();

  static const Map<String, CalculationMethod> _methodByCountry =
      <String, CalculationMethod>{
    // North America
    'US': CalculationMethod.isna,
    'CA': CalculationMethod.isna,
    'MX': CalculationMethod.isna,
    // Gulf / Arabian Peninsula
    'SA': CalculationMethod.makkah,
    'AE': CalculationMethod.dubai,
    'KW': CalculationMethod.kuwait,
    'QA': CalculationMethod.qatar,
    'BH': CalculationMethod.gulf,
    'OM': CalculationMethod.gulf,
    'YE': CalculationMethod.makkah,
    // Levant / North & East Africa
    'EG': CalculationMethod.egypt,
    'SD': CalculationMethod.egypt,
    'SY': CalculationMethod.egypt,
    'LB': CalculationMethod.egypt,
    'IQ': CalculationMethod.egypt,
    'PS': CalculationMethod.egypt,
    'LY': CalculationMethod.egypt,
    'JO': CalculationMethod.jordan,
    'DZ': CalculationMethod.algeria,
    'MA': CalculationMethod.morocco,
    'TN': CalculationMethod.tunisia,
    // Iran / Turkey / Russia
    'IR': CalculationMethod.tehran,
    'TR': CalculationMethod.turkey,
    'RU': CalculationMethod.russia,
    // South & Central Asia
    'PK': CalculationMethod.karachi,
    'IN': CalculationMethod.karachi,
    'BD': CalculationMethod.karachi,
    'AF': CalculationMethod.karachi,
    // South-East Asia
    'ID': CalculationMethod.kemenag,
    'MY': CalculationMethod.jakim,
    'BN': CalculationMethod.jakim,
    'SG': CalculationMethod.singapore,
    // Western Europe with dedicated authorities
    'FR': CalculationMethod.france,
    'PT': CalculationMethod.portugal,
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
