/// Whole-minute corrections a calculation method applies to its own output.
///
/// These are part of the *method's definition* — several authorities publish
/// times that sit a minute or two off the pure astronomical value (most add a
/// minute to Dhuhr so the printed time is safely past the zenith). They are
/// applied on top of the astronomy and before rounding, and are independent of
/// the user's own `tune` offsets, which apply afterwards.
class MethodAdjustments {
  const MethodAdjustments({
    this.fajr = 0,
    this.sunrise = 0,
    this.dhuhr = 0,
    this.asr = 0,
    this.maghrib = 0,
    this.isha = 0,
  });

  /// No corrections — the astronomical values stand as computed.
  static const MethodAdjustments none = MethodAdjustments();

  final int fajr;
  final int sunrise;
  final int dhuhr;
  final int asr;
  final int maghrib;
  final int isha;

  /// Whether every correction is zero.
  bool get isEmpty =>
      fajr == 0 &&
      sunrise == 0 &&
      dhuhr == 0 &&
      asr == 0 &&
      maghrib == 0 &&
      isha == 0;

  MethodAdjustments copyWith({
    int? fajr,
    int? sunrise,
    int? dhuhr,
    int? asr,
    int? maghrib,
    int? isha,
  }) {
    return MethodAdjustments(
      fajr: fajr ?? this.fajr,
      sunrise: sunrise ?? this.sunrise,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MethodAdjustments &&
      other.fajr == fajr &&
      other.sunrise == sunrise &&
      other.dhuhr == dhuhr &&
      other.asr == asr &&
      other.maghrib == maghrib &&
      other.isha == isha;

  @override
  int get hashCode => Object.hash(fajr, sunrise, dhuhr, asr, maghrib, isha);

  @override
  String toString() => 'MethodAdjustments(fajr: $fajr, sunrise: $sunrise, '
      'dhuhr: $dhuhr, asr: $asr, maghrib: $maghrib, isha: $isha)';
}
