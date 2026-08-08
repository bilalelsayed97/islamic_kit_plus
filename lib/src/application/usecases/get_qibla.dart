import 'dart:math' as math;

import '../../domain/models/qibla_direction.dart';
import '../../domain/value_objects/coordinates.dart';

/// Computes the Qibla direction (great-circle bearing to the Ka'aba).
class QiblaCalculator {
  const QiblaCalculator();

  /// Geographic coordinates of the Ka'aba, in degrees.
  static const Coordinates kaaba = Coordinates(21.422517, 39.826166);

  QiblaDirection direction(Coordinates from) {
    final a = _dtr(kaaba.longitude - from.longitude);
    final b = _dtr(90 - from.latitude);
    final c = _dtr(90 - kaaba.latitude);
    var degrees = _rtd(
      math.atan2(
        math.sin(a),
        math.sin(b) * _cot(c) - math.cos(b) * math.cos(a),
      ),
    );
    if (degrees < 0) degrees += 360;
    return QiblaDirection(degrees: degrees, from: from);
  }

  static double _dtr(double d) => d * math.pi / 180.0;
  static double _rtd(double r) => r * 180.0 / math.pi;
  static double _cot(double x) => math.tan(math.pi / 2 - x);
}
