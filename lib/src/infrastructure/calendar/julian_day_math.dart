/// Low-level Julian-Day math for Hijri <-> Gregorian conversion.
///
/// Julian-day conversions for the Gregorian and Hijri calendars,
/// `Date/Julian` and `Date/Hijri`. All values are chronological Julian Day
/// numbers (CJDN); integer/truncating arithmetic is used exactly as in the PHP.
class JulianDayMath {
  const JulianDayMath._();

  /// Truncation with the PHP `intPart` epsilon (±1e-7).
  static double intPart(double x) => x < -0.0000001
      ? (x - 0.0000001).ceilToDouble()
      : (x + 0.0000001).floorToDouble();

  /// Gregorian date -> CJDN.
  ///
  /// Note: the century offset uses the *original* year (matching the PHP, which
  /// reads the century from the unadjusted date even for Jan/Feb).
  static int gregorianToJd(int year, int month, int day) {
    var y = year;
    var m = month;
    final a = (year / 100).floor();
    if (m < 3) {
      y -= 1;
      m += 12;
    }
    final jgc = a - (a / 4).floor() - 2;
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day -
        jgc -
        1524;
  }

  /// CJDN -> Gregorian date.
  static ({int year, int month, int day}) jdToGregorian(num jd) {
    final a = ((jd - 1867216.25) / 36524.25).floor();
    final jgc = a - (a / 4).floor() + 1;
    final b = jd + jgc + 1524;
    final c = ((b - 122.1) / 365.25).floor();
    final d = (365.25 * c).floor();
    var month = ((b - d) / 30.6001).floor();
    final day = ((b - d) - (30.6001 * month).floor()).toInt();
    var cc = c;
    if (month > 13) {
      cc += 1;
      month -= 12;
    }
    month -= 1;
    return (year: cc - 4716, month: month, day: day);
  }

  /// Hijri date -> CJDN (pure arithmetic: the tabular calendar). Only correct
  /// for the mathematical method; a table-driven method must use [tableToJd],
  /// or its two directions disagree wherever the observed month start differs
  /// from the tabular one.
  static int hijriToJd(int year, int month, int day, {int adjust = 0}) {
    return ((11 * year + 3) ~/ 30) +
        354 * year +
        30 * month -
        ((month - 1) ~/ 2) +
        day +
        1948440 -
        385 +
        adjust;
  }

  /// CJDN -> Hijri via a lunation-start table lookup (Umm al-Qura / Diyanet).
  static ({int year, int month, int day, int monthLength}) tableToHijri(
    List<int> data,
    int lunations,
    int jd,
  ) {
    final mcjdn = jd - 2400000;
    var i = 0;
    for (; i < data.length; i++) {
      if (data[i] > mcjdn) break;
    }
    final iln = i + lunations;
    final ii = ((iln - 1) / 12).floor();
    return (
      year: ii + 1,
      month: iln - 12 * ii,
      day: mcjdn - data[i - 1] + 1,
      monthLength: data[i] - data[i - 1],
    );
  }

  /// Hijri date -> CJDN via the lunation-start table: the exact inverse of
  /// [tableToHijri]. A [day] past the month's end runs on into the next month,
  /// as date overflow does everywhere else. `null` when the month is outside
  /// the table.
  static int? tableToJd(
    List<int> data,
    int lunations,
    int year,
    int month,
    int day,
  ) {
    // tableToHijri numbers the lunation that starts at data[i] as
    // i + 1 + lunations, and lunation n is month ((n - 1) mod 12) + 1 of
    // year ((n - 1) div 12) + 1.
    final index = (year - 1) * 12 + month - 1 - lunations;
    if (index < 0 || index >= data.length) return null;
    return data[index] + day - 1 + 2400000;
  }

  /// CJDN -> Hijri via the pure arithmetic (tabular) algorithm.
  static ({int year, int month, int day}) mathematicalToHijri(
    int jd,
    int adjustment,
  ) {
    var l = jd + adjustment - 1948440 + 10632.0;
    final n = intPart((l - 1) / 10631);
    l = l - 10631 * n + 354;
    final j = intPart((10985 - l) / 5316) * intPart((50 * l) / 17719) +
        intPart(l / 5670) * intPart((43 * l) / 15238);
    l = l -
        intPart((30 - j) / 15) * intPart((17719 * j) / 50) -
        intPart(j / 16) * intPart((15238 * j) / 43) +
        29;
    final m = intPart((24 * l) / 709);
    final d = l - intPart((709 * m) / 24);
    final y = 30 * n + j - 30;
    return (year: y.toInt(), month: m.toInt(), day: d.toInt());
  }
}
