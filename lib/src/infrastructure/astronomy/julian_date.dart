/// Julian Day computations used by the prayer-time astronomy.
///
/// Two distinct paths, matching the PHP original exactly:
/// * [julian] — the classic astronomical formula used by sun-angle and mid-day.
/// * [gregorianToJulian] — PHP's `gregoriantojd` (JD at noon) plus the time-of-day
///   fraction, used **only** for the Asr declination.
class JulianDate {
  const JulianDate._();

  /// Classic astronomical Julian Day for civil [year]/[month]/[day] at 00:00.
  static double julian(int year, int month, int day) {
    var y = year;
    var m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floorToDouble();
    final b = 2 - a + (a / 4).floorToDouble();
    return (365.25 * (y + 4716)).floorToDouble() +
        (30.6001 * (m + 1)).floorToDouble() +
        day +
        b -
        1524.5;
  }

  /// Equivalent of PHP `gregorianToJulianDate()`: the integer Julian Day at noon
  /// (`gregoriantojd`) plus the day fraction derived from [date]'s time.
  static double gregorianToJulian(DateTime date) {
    final jd = gregorianToJulianDayNumber(date.month, date.day, date.year);
    var dayFraction = date.hour / 24 - 0.5;
    if (dayFraction < 0) dayFraction += 1;
    final fraction = dayFraction + (date.minute + date.second / 60) / 60 / 24;
    return jd + fraction;
  }

  /// Integer Julian Day Number at noon for a Gregorian date — matches PHP's
  /// `gregoriantojd` (Fliegel & Van Flandern algorithm).
  static int gregorianToJulianDayNumber(int month, int day, int year) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
  }
}
