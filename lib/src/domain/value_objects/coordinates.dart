/// An immutable geographic coordinate in decimal degrees.
class Coordinates {
  const Coordinates(this.latitude, this.longitude);

  /// Latitude in decimal degrees, positive north.
  final double latitude;

  /// Longitude in decimal degrees, positive east.
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is Coordinates &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'Coordinates($latitude, $longitude)';
}
