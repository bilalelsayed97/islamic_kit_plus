import '../enums/midnight_mode.dart';
import 'coordinates.dart';

/// Strongly-typed twilight parameters for a calculation method.
///
/// This replaces the PHP library's stringly-typed `params` map (which mixed
/// angles and `'90 min'` strings). Isha and Maghrib can each be defined either
/// as an angle **or** as a number of minutes after the preceding event.
class MethodParams {
  const MethodParams({
    this.fajrAngle = 0,
    this.ishaAngle,
    this.ishaMinutesAfterMaghrib,
    this.maghribAngle,
    this.maghribMinutesAfterSunset,
    this.midnightMode,
    this.location,
  });

  /// Fajr twilight angle in degrees below the horizon.
  final double fajrAngle;

  /// Isha twilight angle in degrees, if defined by angle.
  final double? ishaAngle;

  /// Minutes after Maghrib for Isha, if defined by a fixed interval.
  final int? ishaMinutesAfterMaghrib;

  /// Maghrib angle in degrees, if defined by angle (rare; e.g. Jafari/Tehran).
  final double? maghribAngle;

  /// Minutes after Sunset for Maghrib, if defined by a fixed interval.
  final int? maghribMinutesAfterSunset;

  /// Midnight mode implied by the method (e.g. Jafari for Shia methods).
  final MidnightMode? midnightMode;

  /// Reference location associated with the method (informational).
  final Coordinates? location;

  /// Whether Isha is defined as a fixed number of minutes after Maghrib.
  bool get ishaIsInterval => ishaMinutesAfterMaghrib != null;

  /// Whether Maghrib is defined as a fixed number of minutes after Sunset.
  bool get maghribIsInterval => maghribMinutesAfterSunset != null;

  MethodParams copyWith({
    double? fajrAngle,
    double? ishaAngle,
    int? ishaMinutesAfterMaghrib,
    double? maghribAngle,
    int? maghribMinutesAfterSunset,
    MidnightMode? midnightMode,
    Coordinates? location,
  }) {
    return MethodParams(
      fajrAngle: fajrAngle ?? this.fajrAngle,
      ishaAngle: ishaAngle ?? this.ishaAngle,
      ishaMinutesAfterMaghrib:
          ishaMinutesAfterMaghrib ?? this.ishaMinutesAfterMaghrib,
      maghribAngle: maghribAngle ?? this.maghribAngle,
      maghribMinutesAfterSunset:
          maghribMinutesAfterSunset ?? this.maghribMinutesAfterSunset,
      midnightMode: midnightMode ?? this.midnightMode,
      location: location ?? this.location,
    );
  }
}
