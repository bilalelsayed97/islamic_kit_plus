import '../enums/prayer.dart';
import '../enums/shafaq.dart';
import '../value_objects/coordinates.dart';

/// Inputs handed to a [TwilightStrategy] after the base astronomical
/// computation. [times] is the mutable map of raw local-hour values.
class TwilightContext {
  const TwilightContext({
    required this.times,
    required this.date,
    required this.coordinates,
    required this.shafaq,
    required this.imsakMinutes,
  });

  final Map<Prayer, double?> times;
  final DateTime date;
  final Coordinates coordinates;
  final Shafaq shafaq;

  /// Minutes before Fajr used for Imsak (when Imsak is interval-based).
  final int imsakMinutes;
}

/// Strategy for deriving Fajr / Imsak / Isha when a method does not use a fixed
/// twilight angle (e.g. the Moonsighting Committee Worldwide method).
///
/// Implementations mutate [TwilightContext.times] in place.
abstract class TwilightStrategy {
  void recalculate(TwilightContext context);
}
