import '../enums/prayer.dart';
import '../enums/time_format.dart';
import 'calculation_meta.dart';
import 'date_info.dart';
import 'prayer_time.dart';

/// The result of a timings calculation for a single date and location.
///
/// Bundles the computed [timings], the [date] block (Gregorian + Hijri) and the
/// [meta] echo — the same triple aladhan returns under `data`. A calendar is a
/// list of these.
class PrayerResult {
  const PrayerResult({
    required this.timings,
    required this.date,
    required this.meta,
  });

  final PrayerTimings timings;
  final DateInfo date;
  final CalculationMeta meta;

  /// Shortcut to a single [PrayerTime].
  PrayerTime time(Prayer prayer) => timings.time(prayer);

  /// Shortcut to a single formatted prayer string.
  String formatted(Prayer prayer, [TimeFormat format = TimeFormat.h24]) =>
      timings.formatted(prayer, format);
}
