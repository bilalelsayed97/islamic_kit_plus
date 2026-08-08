import '../enums/calendar_method.dart';
import '../models/hijri_date.dart';

/// Converts between Gregorian and Hijri dates for a specific [method].
abstract class HijriConverter {
  CalendarMethod get method;

  /// Converts a Gregorian [date] to a fully-populated [HijriDate]
  /// (localized names + holidays included).
  ///
  /// [adjustment] shifts the result by whole days (only honored by the
  /// Mathematical method; ignored by table-based methods).
  HijriDate fromGregorian(DateTime date, {int adjustment = 0});

  /// Converts a Hijri date to the Gregorian [DateTime] at midnight.
  ///
  /// [adjustment] shifts the result by whole days (only honored by the
  /// Mathematical method; ignored by table-based methods).
  DateTime toGregorian(int year, int month, int day, {int adjustment = 0});
}
