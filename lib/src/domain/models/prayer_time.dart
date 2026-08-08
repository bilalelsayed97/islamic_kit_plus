import '../enums/language.dart';
import '../enums/prayer.dart';
import '../enums/time_format.dart';
import '../services/time_formatting.dart';

/// A single computed prayer time.
///
/// [hours] is the raw fractional-hours value in the *local* (offset-adjusted)
/// day. It may be negative or exceed 24 when the event rolls into the previous
/// or next calendar day; formatting and [toUtc] handle the wrap. A `null` (or
/// NaN) [hours] means the time is invalid for the given latitude.
class PrayerTime {
  const PrayerTime({
    required this.prayer,
    required this.hours,
    required this.date,
    required this.utcOffset,
  });

  final Prayer prayer;
  final double? hours;

  /// The civil calendar date the times were computed for.
  final DateTime date;

  /// The UTC offset used to localize the times.
  final Duration utcOffset;

  bool get isValid => hours != null && !hours!.isNaN;

  /// Localized display name of the prayer.
  String name(Language language) => prayer.localizedName(language);

  /// Formats the time using [format] (defaults to 24-hour).
  String format([TimeFormat format = TimeFormat.h24]) =>
      formatHours(hours, format, date, utcOffset);

  /// The absolute instant as a UTC [DateTime], or `null` if invalid.
  DateTime? toUtc() {
    if (!isValid) return null;
    final wall = DateTime.utc(date.year, date.month, date.day)
        .add(Duration(milliseconds: (hours! * 3600000).round()));
    return wall.subtract(utcOffset);
  }

  @override
  String toString() => '${prayer.key}: ${format()}';
}

/// The full set of computed times for a single date and location.
class PrayerTimings {
  const PrayerTimings({
    required this.raw,
    required this.date,
    required this.utcOffset,
  });

  /// Raw fractional-hours per prayer (null/NaN = invalid).
  final Map<Prayer, double?> raw;

  /// The civil calendar date the times were computed for.
  final DateTime date;

  /// The UTC offset used to localize the times.
  final Duration utcOffset;

  /// Returns the [PrayerTime] for [prayer].
  PrayerTime time(Prayer prayer) => PrayerTime(
        prayer: prayer,
        hours: raw[prayer],
        date: date,
        utcOffset: utcOffset,
      );

  /// Formats a single prayer.
  String formatted(Prayer prayer, [TimeFormat format = TimeFormat.h24]) =>
      time(prayer).format(format);

  /// A map of every present prayer to its formatted string.
  Map<Prayer, String> toFormattedMap([TimeFormat format = TimeFormat.h24]) => {
        for (final prayer in raw.keys) prayer: formatted(prayer, format),
      };
}
