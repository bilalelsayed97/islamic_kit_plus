import '../enums/midnight_mode.dart';
import 'coordinates.dart';
import 'method_adjustments.dart';

/// Strongly-typed twilight parameters for a calculation method.
///
/// Isha and Maghrib can each be defined either as an angle **or** as a number
/// of minutes after the preceding event. [adjustments] carries the whole-minute
/// corrections the authority publishes on top of the astronomy.
class MethodParams {
  const MethodParams({
    this.fajrAngle = 0,
    this.ishaAngle,
    this.ishaMinutesAfterMaghrib,
    this.ramadanIshaMinutesAfterMaghrib,
    this.maghribAngle,
    this.maghribMinutesAfterSunset,
    this.adjustments = MethodAdjustments.none,
    this.midnightMode,
    this.location,
  });

  /// Fajr twilight angle in degrees below the horizon.
  final double fajrAngle;

  /// Isha twilight angle in degrees, if defined by angle.
  final double? ishaAngle;

  /// Minutes after Maghrib for Isha, if defined by a fixed interval.
  final int? ishaMinutesAfterMaghrib;

  /// Interval used instead of [ishaMinutesAfterMaghrib] during Ramadan.
  ///
  /// Umm al-Qura lengthens its 90-minute interval to 120 minutes for the
  /// month; no other method varies by season.
  final int? ramadanIshaMinutesAfterMaghrib;

  /// Maghrib angle in degrees, if defined by angle (rare; e.g. Jafari/Tehran).
  final double? maghribAngle;

  /// Minutes after Sunset for Maghrib, if defined by a fixed interval.
  final int? maghribMinutesAfterSunset;

  /// Whole-minute corrections the method applies to its own times.
  final MethodAdjustments adjustments;

  /// Midnight mode implied by the method (e.g. Jafari for Shia methods).
  final MidnightMode? midnightMode;

  /// Reference location associated with the method (informational).
  final Coordinates? location;

  /// Whether Isha is defined as a fixed number of minutes after Maghrib.
  bool get ishaIsInterval => ishaMinutesAfterMaghrib != null;

  /// Whether Maghrib is defined as a fixed number of minutes after Sunset.
  bool get maghribIsInterval => maghribMinutesAfterSunset != null;

  /// Whether the Isha interval changes during Ramadan.
  bool get hasRamadanIshaInterval => ramadanIshaMinutesAfterMaghrib != null;

  /// These params with the Ramadan Isha interval applied, when the method
  /// defines one. Returns `this` unchanged otherwise.
  MethodParams forRamadan() {
    final ramadan = ramadanIshaMinutesAfterMaghrib;
    if (ramadan == null) return this;
    return copyWith(ishaMinutesAfterMaghrib: ramadan);
  }

  MethodParams copyWith({
    double? fajrAngle,
    double? ishaAngle,
    int? ishaMinutesAfterMaghrib,
    int? ramadanIshaMinutesAfterMaghrib,
    double? maghribAngle,
    int? maghribMinutesAfterSunset,
    MethodAdjustments? adjustments,
    MidnightMode? midnightMode,
    Coordinates? location,
  }) {
    return MethodParams(
      fajrAngle: fajrAngle ?? this.fajrAngle,
      ishaAngle: ishaAngle ?? this.ishaAngle,
      ishaMinutesAfterMaghrib:
          ishaMinutesAfterMaghrib ?? this.ishaMinutesAfterMaghrib,
      ramadanIshaMinutesAfterMaghrib:
          ramadanIshaMinutesAfterMaghrib ?? this.ramadanIshaMinutesAfterMaghrib,
      maghribAngle: maghribAngle ?? this.maghribAngle,
      maghribMinutesAfterSunset:
          maghribMinutesAfterSunset ?? this.maghribMinutesAfterSunset,
      adjustments: adjustments ?? this.adjustments,
      midnightMode: midnightMode ?? this.midnightMode,
      location: location ?? this.location,
    );
  }
}
