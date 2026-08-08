import '../value_objects/coordinates.dart';

/// The direction of the Qibla from an observer's location.
class QiblaDirection {
  const QiblaDirection({required this.degrees, required this.from});

  /// Bearing to the Ka'aba measured clockwise from true north, in `[0, 360)`.
  final double degrees;

  /// The observer's location.
  final Coordinates from;

  @override
  String toString() =>
      'QiblaDirection(${degrees.toStringAsFixed(2)}° from ${from.latitude}, '
      '${from.longitude})';
}
