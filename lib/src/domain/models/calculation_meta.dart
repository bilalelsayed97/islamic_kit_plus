import '../enums/asr_school.dart';
import '../enums/calculation_method.dart';
import '../enums/high_latitude_rule.dart';
import '../enums/midnight_mode.dart';
import '../enums/prayer.dart';
import '../enums/shafaq.dart';
import '../value_objects/coordinates.dart';
import '../value_objects/method_params.dart';

/// Echo of the settings used for a calculation (mirrors aladhan `meta`).
class CalculationMeta {
  const CalculationMeta({
    required this.coordinates,
    required this.timezone,
    required this.method,
    required this.methodParams,
    required this.school,
    required this.midnightMode,
    required this.latitudeAdjustmentMethod,
    required this.shafaq,
    required this.offsets,
  });

  final Coordinates coordinates;

  /// Timezone label (an IANA name if the caller supplied one, else `UTC±HH:MM`).
  final String timezone;

  final CalculationMethod method;

  /// The effective params (equals `method.params` unless a custom method or an
  /// overriding shadow/interval was supplied).
  final MethodParams methodParams;

  final AsrSchool school;
  final MidnightMode midnightMode;
  final HighLatitudeRule latitudeAdjustmentMethod;
  final Shafaq shafaq;

  /// Per-prayer tuning offsets in minutes.
  final Map<Prayer, int> offsets;
}
