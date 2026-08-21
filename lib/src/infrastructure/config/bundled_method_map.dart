import '../../domain/enums/calculation_method.dart';
import '../../domain/models/city_entry.dart';
import '../../domain/models/country_info.dart';

/// Translates the bundled database's `calc_method` column into a
/// [CalculationMethod].
///
/// > **These ids are not aladhan ids.** The `prayer_times_country_lookups`
/// > table numbers its authorities independently, and the two schemes collide
/// > above 5 — database id 7 is Kuwait while aladhan id 7 is Tehran. Never
/// > pass a `calc_method` value to [CalculationMethod.fromId]; route it
/// > through [methodForBundledId] instead.
class BundledMethodMap {
  const BundledMethodMap._();

  static const Map<int, CalculationMethod> _byId = <int, CalculationMethod>{
    1: CalculationMethod.karachi,
    2: CalculationMethod.isna,
    3: CalculationMethod.mwl,
    4: CalculationMethod.makkah,
    5: CalculationMethod.egypt,
    6: CalculationMethod.dubai,
    7: CalculationMethod.kuwait,
    8: CalculationMethod.qatar,
    9: CalculationMethod.singapore,
    10: CalculationMethod.algeria,
    11: CalculationMethod.france,
    12: CalculationMethod.russia,
    13: CalculationMethod.tunisia,
    14: CalculationMethod.turkey,
    15: CalculationMethod.morocco,
    16: CalculationMethod.jordan,
    17: CalculationMethod.oman,
    18: CalculationMethod.munich,
    19: CalculationMethod.maldives,
    20: CalculationMethod.canada,
    21: CalculationMethod.tajikistan,
    22: CalculationMethod.vienna,
    23: CalculationMethod.belgium,
    24: CalculationMethod.sudan,
    25: CalculationMethod.libya,
    26: CalculationMethod.iraq,
    27: CalculationMethod.luxembourg,
    28: CalculationMethod.tehran,
    29: CalculationMethod.moonsighting,
    30: CalculationMethod.custom,
  };

  /// The method for a database `calc_method` value.
  ///
  /// Returns `null` for an unknown id so callers can decide whether to fall
  /// back; use [methodForBundledIdOrDefault] for the engine's own default.
  static CalculationMethod? methodForBundledId(int? id) =>
      id == null ? null : _byId[id];

  /// As [methodForBundledId], falling back to [CalculationMethod.mwl] — the
  /// bucket the database itself assigns to most of the world.
  static CalculationMethod methodForBundledIdOrDefault(int? id) =>
      methodForBundledId(id) ?? CalculationMethod.mwl;

  /// Every database id the map understands.
  static Iterable<int> get knownIds => _byId.keys;
}

/// Resolves a country row's recommended calculation method.
extension CountryInfoMethod on CountryInfo {
  /// The method the database recommends, or `null` when it records none.
  CalculationMethod? get calculationMethod =>
      BundledMethodMap.methodForBundledId(calculationMethodId);
}

/// Resolves a city row's recommended calculation method (from its country).
extension CityEntryMethod on CityEntry {
  /// The method the database recommends for this city's country, or `null`
  /// when it records none.
  CalculationMethod? get calculationMethod =>
      BundledMethodMap.methodForBundledId(calculationMethodId);
}
