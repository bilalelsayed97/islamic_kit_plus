/// islamic_kit_plus — offline, dependency-free Islamic prayer times, Hijri
/// calendar, qibla and calendars for Dart.
///
/// Prayer times are solved from Jean Meeus' solar position with three-point
/// interpolation, alongside a Hijri calendar with four methods,
/// qibla, calendars, an aladhan.com-compatible JSON model and English/Arabic
/// localization.
///
/// Everything is computed locally — no network, no runtime dependencies.
library;

// Enums (strongly-typed inputs).
export 'src/domain/enums/asr_school.dart';
export 'src/domain/enums/calculation_method.dart';
export 'src/domain/enums/calendar_method.dart';
export 'src/domain/enums/high_latitude_rule.dart';
export 'src/domain/enums/language.dart';
export 'src/domain/enums/midnight_mode.dart';
export 'src/domain/enums/prayer.dart';
export 'src/domain/enums/shafaq.dart';
export 'src/domain/enums/time_format.dart';

// Value objects.
export 'src/domain/value_objects/calculation_parameters.dart';
export 'src/domain/value_objects/coordinates.dart';
export 'src/domain/value_objects/method_adjustments.dart';
export 'src/domain/value_objects/method_params.dart';
export 'src/domain/value_objects/tune.dart';

// Models.
export 'src/domain/models/calculation_meta.dart';
export 'src/domain/models/city.dart';
export 'src/domain/models/city_entry.dart';
export 'src/domain/models/country_info.dart';
export 'src/domain/models/date_info.dart';
export 'src/domain/models/gregorian_date.dart';
export 'src/domain/models/hijri_date.dart';
export 'src/domain/models/next_prayer.dart';
export 'src/domain/models/prayer_result.dart';
export 'src/domain/models/prayer_time.dart';
export 'src/domain/models/qibla_direction.dart';
export 'src/domain/models/time_zone_info.dart';

// Ports (implement these to customize behaviour).
export 'src/domain/ports/geocoder.dart';
export 'src/domain/ports/hijri_converter.dart';
export 'src/domain/ports/twilight_strategy.dart';

// Domain services.
export 'src/domain/services/time_formatting.dart' show invalidTime;

// Application (facade + use cases + aladhan serialization).
export 'src/application/prayer_calculator.dart';
export 'src/application/prayer_times_service.dart';
export 'src/application/serialization/aladhan_serializer.dart';
export 'src/application/usecases/get_qibla.dart';

// Infrastructure the caller may want to reuse or swap.
export 'src/infrastructure/calendar/hijri_converter_factory.dart';
// Translates the bundled database's `calc_method` column into a
// CalculationMethod. Those ids are the database's own numbering and collide
// with aladhan's, so this map is the only safe way to read that column.
export 'src/infrastructure/config/bundled_method_map.dart';
export 'src/infrastructure/config/location_defaults.dart';
export 'src/infrastructure/geocoding/bundled_city_geocoder.dart'
    show BundledCityGeocoder;
export 'src/infrastructure/geocoding/city_directory.dart';
export 'src/infrastructure/geocoding/data/city_dataset.dart'
    show CityRecord, kCityDataset;
// The generated `country_id` <-> ISO 3166-1 alpha-2 mapping. The bundled
// database keys countries by integer id; callers that persist or branch on a
// country need the ISO code, so both directions are public.
export 'src/infrastructure/geocoding/data/country_iso_map.dart'
    show kCountryIdToIso, kIsoToCountryId;
// The bundled 138k-city SQLite geocoder (sqlite3, no Flutter binding needed to
// open a file). For loading the bundled asset in a Flutter app, import
// `islamic_kit_plus_flutter.dart`.
export 'src/infrastructure/geocoding/sqlite_city_geocoder.dart';
export 'src/infrastructure/localization/localizer.dart'
    show Localizer, LocalizedName;
export 'src/infrastructure/twilight/moonsighting_twilight.dart';
