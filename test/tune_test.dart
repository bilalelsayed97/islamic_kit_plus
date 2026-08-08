import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit_plus/islamic_kit_plus.dart';

void main() {
  const london = Coordinates(51.508515, -0.1254872);
  final service = PrayerTimesService();

  test('per-prayer tune shifts the computed time by the given minutes', () {
    const base = CalculationParameters(
      method: CalculationMethod.isna,
      utcOffset: Duration(hours: 1),
    );
    final untuned = service.timings(DateTime(2014, 4, 24), london, base);
    expect(untuned.formatted(Prayer.fajr), '03:57');

    final tuned = service.timings(
      DateTime(2014, 4, 24),
      london,
      base.copyWith(tune: const Tune(fajr: 5)), // +5 minutes
    );
    expect(tuned.formatted(Prayer.fajr), '04:02');
  });

  test('Tune round-trips the aladhan CSV order', () {
    final tune = Tune.fromCsv('5,3,5,7,9,-1,0,8,-6');
    expect(tune.imsak, 5);
    expect(tune.fajr, 3);
    expect(tune.maghrib, -1); // Maghrib precedes Sunset in the aladhan order
    expect(tune.sunset, 0);
    expect(tune.midnight, -6);
    expect(tune.toCsv(), '5,3,5,7,9,-1,0,8,-6');
  });

  test('offsets appear in the aladhan meta block', () {
    final json = service
        .timings(
          DateTime(2014, 4, 24),
          london,
          const CalculationParameters(
            method: CalculationMethod.isna,
            utcOffset: Duration(hours: 1),
            tune: Tune(fajr: 3, isha: 8),
          ),
        )
        .toAladhanJson();
    final offset = ((json['data'] as Map)['meta'] as Map)['offset'] as Map;
    expect(offset['Fajr'], 3);
    expect(offset['Isha'], 8);
    expect(offset['Dhuhr'], 0);
  });
}
