import '../enums/prayer.dart';

/// Per-prayer time adjustments, in minutes — the equivalent of the aladhan
/// `tune` parameter.
///
/// Field order matches the aladhan contract exactly:
/// `Imsak, Fajr, Sunrise, Dhuhr, Asr, Maghrib, Sunset, Isha, Midnight`
/// (note Maghrib comes before Sunset). Each value defaults to `0`.
class Tune {
  const Tune({
    this.imsak = 0,
    this.fajr = 0,
    this.sunrise = 0,
    this.dhuhr = 0,
    this.asr = 0,
    this.maghrib = 0,
    this.sunset = 0,
    this.isha = 0,
    this.midnight = 0,
  });

  /// No adjustments.
  static const Tune none = Tune();

  /// Parses an aladhan `tune` CSV string, e.g. `"5,3,5,7,9,-1,0,8,-6"`.
  /// Missing trailing values default to `0`.
  factory Tune.fromCsv(String csv) {
    final parts = csv.split(',');
    int at(int i) =>
        i < parts.length ? (int.tryParse(parts[i].trim()) ?? 0) : 0;
    return Tune(
      imsak: at(0),
      fajr: at(1),
      sunrise: at(2),
      dhuhr: at(3),
      asr: at(4),
      maghrib: at(5),
      sunset: at(6),
      isha: at(7),
      midnight: at(8),
    );
  }

  final int imsak;
  final int fajr;
  final int sunrise;
  final int dhuhr;
  final int asr;
  final int maghrib;
  final int sunset;
  final int isha;
  final int midnight;

  /// Whether any adjustment is non-zero.
  bool get isEmpty =>
      imsak == 0 &&
      fajr == 0 &&
      sunrise == 0 &&
      dhuhr == 0 &&
      asr == 0 &&
      maghrib == 0 &&
      sunset == 0 &&
      isha == 0 &&
      midnight == 0;

  /// The aladhan `tune` CSV, e.g. `"5,3,5,7,9,-1,0,8,-6"`.
  String toCsv() =>
      '$imsak,$fajr,$sunrise,$dhuhr,$asr,$maghrib,$sunset,$isha,$midnight';

  /// A map keyed by [Prayer], in aladhan `offset` order.
  Map<Prayer, int> toMap() => <Prayer, int>{
        Prayer.imsak: imsak,
        Prayer.fajr: fajr,
        Prayer.sunrise: sunrise,
        Prayer.dhuhr: dhuhr,
        Prayer.asr: asr,
        Prayer.sunset: sunset,
        Prayer.maghrib: maghrib,
        Prayer.isha: isha,
        Prayer.midnight: midnight,
      };

  Tune copyWith({
    int? imsak,
    int? fajr,
    int? sunrise,
    int? dhuhr,
    int? asr,
    int? maghrib,
    int? sunset,
    int? isha,
    int? midnight,
  }) {
    return Tune(
      imsak: imsak ?? this.imsak,
      fajr: fajr ?? this.fajr,
      sunrise: sunrise ?? this.sunrise,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      sunset: sunset ?? this.sunset,
      isha: isha ?? this.isha,
      midnight: midnight ?? this.midnight,
    );
  }

  @override
  bool operator ==(Object other) => other is Tune && other.toCsv() == toCsv();

  @override
  int get hashCode => toCsv().hashCode;
}
