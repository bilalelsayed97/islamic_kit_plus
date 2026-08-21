// ignore_for_file: avoid_print
//
// Example usage of islamic_kit_plus (core API — no Flutter binding required).
//
// Run with: dart run example/main.dart
//
// For by-city / by-address lookups backed by the bundled city database in
// a Flutter app, import 'package:islamic_kit_plus/islamic_kit_plus_flutter.dart'
// and do:
//   final geocoder = await loadBundledCityGeocoder();
//   final service = PrayerTimesService(geocoder: geocoder);
//   service.timingsByCity('London', country: 'GB', date: DateTime.now());

import 'package:islamic_kit_plus/islamic_kit_plus.dart';

void main() {
  final service = PrayerTimesService();

  const london = Coordinates(51.508515, -0.1254872);
  const params = CalculationParameters(
    method: CalculationMethod.isna,
    utcOffset: Duration(hours: 1), // London BST
  );

  final result = service.timings(DateTime(2014, 4, 24), london, params);

  print('Prayer times — ${result.date.readable}');
  for (final prayer in Prayer.dailyObligatory) {
    final en = prayer.title(Language.en);
    final ar = prayer.title(Language.ar);
    print('  $en / $ar: ${result.formatted(prayer)}');
  }

  final hijri = result.date.hijri;
  print('Hijri: ${hijri.day} ${hijri.monthEn} ${hijri.year} '
      '(${hijri.monthAr})');

  final next =
      service.nextPrayer(DateTime(2014, 4, 24, 13, 30), london, params);
  print('Next prayer: ${next.prayer.title(Language.en)} at '
      '${next.time.format()}');

  final qibla = service.qibla(london);
  print('Qibla: ${qibla.degrees.toStringAsFixed(2)}° from true north');

  // aladhan-compatible JSON:
  final json = result.toAladhanJson();
  print('aladhan JSON code: ${json['code']}');
}
