import '../enums/shafaq.dart';

/// Supplies seasonal Fajr/Isha twilight for methods that do not use a fixed
/// angle — today only the Moonsighting Committee Worldwide method.
///
/// Implementations return whole seconds relative to sunrise/sunset. The engine
/// owns how those values are combined with the angle-based candidates (the
/// seasonal values act as *bounds*, not replacements), so a strategy only has
/// to answer the seasonal question.
abstract class TwilightStrategy {
  /// Seconds **before** sunrise at which Fajr begins on [date] at [latitude].
  int fajrSecondsBeforeSunrise(DateTime date, double latitude);

  /// Seconds **after** sunset at which Isha begins on [date] at [latitude],
  /// for the requested [shafaq] (twilight colour).
  int ishaSecondsAfterSunset(DateTime date, double latitude, Shafaq shafaq);
}
