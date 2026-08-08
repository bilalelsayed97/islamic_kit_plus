import 'gregorian_date.dart';
import 'hijri_date.dart';

/// The combined date block returned with each result: a human-readable label,
/// a Unix timestamp, and both the Gregorian and Hijri representations.
class DateInfo {
  const DateInfo({
    required this.readable,
    required this.timestamp,
    required this.gregorian,
    required this.hijri,
  });

  /// e.g. `"01 Jan 2025"`.
  final String readable;

  /// Unix timestamp (seconds) of the civil date at the used UTC offset.
  final int timestamp;

  final GregorianDate gregorian;
  final HijriDate hijri;
}
