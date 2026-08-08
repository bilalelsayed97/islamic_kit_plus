import '../enums/time_format.dart';

/// Sentinel returned when a time cannot be computed (e.g. sun never reaches the
/// required angle at extreme latitudes). Matches the PHP `INVALID_TIME`.
const String invalidTime = '-----';

/// Positive-modulo wrap to the range `[0, 24)`.
double fixHour(double a) {
  final r = a - 24 * (a / 24).floorToDouble();
  return r < 0 ? r + 24 : r;
}

String _two(int n) => n < 10 ? '0$n' : '$n';

String _offsetSuffix(Duration offset) {
  final sign = offset.isNegative ? '-' : '+';
  final abs = offset.abs();
  return '$sign${_two(abs.inHours)}:${_two(abs.inMinutes % 60)}';
}

/// Formats a raw fractional-hours value using [format].
///
/// Faithful port of `PrayerTimes::getFormattedTime`: adds 0.5 minutes for
/// rounding before truncating clock formats; the ISO-8601 path uses the raw
/// (pre-rounding) value offset from midnight of [date] and appends [utcOffset].
String formatHours(
  double? hours,
  TimeFormat format,
  DateTime date,
  Duration utcOffset,
) {
  if (hours == null || hours.isNaN) return invalidTime;
  if (format == TimeFormat.float) return '$hours';

  // 0.5-minute rounding, applied before truncation for every non-float format
  // (including ISO-8601), matching the PHP original.
  final t = hours + 0.5 / 60;

  if (format == TimeFormat.iso8601) {
    final totalMinutes = t > 0 ? (t * 60).floor() : -(-t * 60).ceil();
    final dt = DateTime(date.year, date.month, date.day)
        .add(Duration(minutes: totalMinutes));
    final stamp = '${dt.year.toString().padLeft(4, '0')}-${_two(dt.month)}-'
        '${_two(dt.day)}T${_two(dt.hour)}:${_two(dt.minute)}:${_two(dt.second)}';
    return '$stamp${_offsetSuffix(utcOffset)}';
  }

  final ft = fixHour(t);
  final h = ft.floor();
  final m = ((ft - h) * 60).floor();
  if (format == TimeFormat.h24) return '${_two(h)}:${_two(m)}';

  final hour12 = (h + 12 - 1) % 12 + 1;
  final body = '$hour12:${_two(m)}';
  if (format == TimeFormat.h12) return '$body ${h < 12 ? 'am' : 'pm'}';
  return body; // h12NoSuffix
}
