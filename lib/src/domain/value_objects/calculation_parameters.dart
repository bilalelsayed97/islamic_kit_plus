import '../enums/asr_school.dart';
import '../enums/calculation_method.dart';
import '../enums/calendar_method.dart';
import '../enums/high_latitude_rule.dart';
import '../enums/midnight_mode.dart';
import '../enums/shafaq.dart';
import 'method_params.dart';
import 'tune.dart';

/// All configuration for a calculation. Immutable; use [copyWith] to derive a
/// tweaked copy (fluent-builder style).
///
/// The caller supplies [utcOffset] because the package has no timezone
/// database — this keeps it dependency-free. Include any DST in the offset you
/// pass for the target date.
class CalculationParameters {
  const CalculationParameters({
    this.method = CalculationMethod.mwl,
    this.customMethod,
    this.school = AsrSchool.standard,
    this.asrShadowFactor,
    this.midnightMode,
    this.highLatitudeRule = HighLatitudeRule.middleOfNight,
    this.utcOffset = Duration.zero,
    this.elevation = 0,
    this.shafaq = Shafaq.general,
    this.tune = const Tune(),
    this.imsakMinutes = 10,
    this.dhuhrMinutes = 0,
    this.calendarMethod = CalendarMethod.hjcosa,
    this.timezoneName,
  });

  final CalculationMethod method;

  /// Params used when [method] is [CalculationMethod.custom].
  final MethodParams? customMethod;

  final AsrSchool school;

  /// Overrides the school's Asr shadow factor when non-null.
  final double? asrShadowFactor;

  /// Overrides the method's implied midnight mode when non-null.
  final MidnightMode? midnightMode;

  /// How Fajr and Isha are bounded when the sun never reaches their angle.
  ///
  /// Defaults to [HighLatitudeRule.middleOfNight]. [HighLatitudeRule.none]
  /// disables the bound entirely, so an unreachable angle yields an invalid
  /// time instead.
  final HighLatitudeRule highLatitudeRule;

  /// UTC offset for the target date (caller-provided; include DST if relevant).
  final Duration utcOffset;

  /// Observer elevation in metres (affects sunrise/sunset).
  final double elevation;

  /// Shafaq used by the Moonsighting method for Isha.
  final Shafaq shafaq;

  /// Per-prayer tuning offsets in minutes (aladhan `tune`).
  final Tune tune;

  /// Minutes before Fajr for Imsak.
  final int imsakMinutes;

  /// Minutes added to Dhuhr.
  final int dhuhrMinutes;

  /// Hijri calendar method for the date block.
  final CalendarMethod calendarMethod;

  /// Optional timezone label echoed in `meta.timezone` (informational only).
  final String? timezoneName;

  /// The params in effect (custom-aware).
  MethodParams get effectiveParams => method == CalculationMethod.custom
      ? (customMethod ?? method.params)
      : method.params;

  /// Midnight mode after resolving overrides and the method default.
  ///
  /// Defaults to [MidnightMode.jafari] — the night measured from sunset to the
  /// following Fajr, which is the basis used for Midnight and the night
  /// thirds. Pass [MidnightMode.standard] explicitly for the
  /// sunset-to-sunrise night used by the aladhan API.
  MidnightMode get resolvedMidnightMode =>
      midnightMode ?? effectiveParams.midnightMode ?? MidnightMode.jafari;

  /// Asr shadow factor after resolving the override / school.
  double get resolvedShadowFactor =>
      asrShadowFactor ?? school.shadowFactor.toDouble();

  /// High-latitude rule in effect.
  ///
  /// Kept as a separate getter for the aladhan `meta` echo; the Moonsighting
  /// method supplies its own seasonal bounds and only consults this to see
  /// whether bounding is switched off entirely.
  HighLatitudeRule get resolvedHighLatitudeRule => highLatitudeRule;

  CalculationParameters copyWith({
    CalculationMethod? method,
    MethodParams? customMethod,
    AsrSchool? school,
    double? asrShadowFactor,
    MidnightMode? midnightMode,
    HighLatitudeRule? highLatitudeRule,
    Duration? utcOffset,
    double? elevation,
    Shafaq? shafaq,
    Tune? tune,
    int? imsakMinutes,
    int? dhuhrMinutes,
    CalendarMethod? calendarMethod,
    String? timezoneName,
  }) {
    return CalculationParameters(
      method: method ?? this.method,
      customMethod: customMethod ?? this.customMethod,
      school: school ?? this.school,
      asrShadowFactor: asrShadowFactor ?? this.asrShadowFactor,
      midnightMode: midnightMode ?? this.midnightMode,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      utcOffset: utcOffset ?? this.utcOffset,
      elevation: elevation ?? this.elevation,
      shafaq: shafaq ?? this.shafaq,
      tune: tune ?? this.tune,
      imsakMinutes: imsakMinutes ?? this.imsakMinutes,
      dhuhrMinutes: dhuhrMinutes ?? this.dhuhrMinutes,
      calendarMethod: calendarMethod ?? this.calendarMethod,
      timezoneName: timezoneName ?? this.timezoneName,
    );
  }
}
