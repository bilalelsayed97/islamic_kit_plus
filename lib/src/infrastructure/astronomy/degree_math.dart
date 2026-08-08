import 'dart:math' as math;

/// Degree-based trigonometry helpers. Faithful port of the PHP `DMath` class —
/// every function takes and returns **degrees**.
class DegreeMath {
  const DegreeMath._();

  /// Degrees to radians.
  static double dtr(double d) => d * math.pi / 180.0;

  /// Radians to degrees.
  static double rtd(double r) => r * 180.0 / math.pi;

  static double sin(double d) => math.sin(dtr(d));
  static double cos(double d) => math.cos(dtr(d));
  static double tan(double d) => math.tan(dtr(d));

  static double arcsin(double d) => rtd(math.asin(d));
  static double arccos(double d) => rtd(math.acos(d));
  static double arctan(double d) => rtd(math.atan(d));

  static double arccot(double x) => rtd(math.atan(1 / x));
  static double arctan2(double y, double x) => rtd(math.atan2(y, x));

  static double fixAngle(double a) => fix(a, 360);
  static double fixHour(double a) => fix(a, 24);

  /// Positive-modulo: `a mod b` mapped into `[0, b)`.
  static double fix(double a, double b) {
    final r = a - b * (a / b).floorToDouble();
    return r < 0 ? r + b : r;
  }
}
