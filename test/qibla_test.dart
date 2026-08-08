import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit_plus/islamic_kit_plus.dart';

void main() {
  test('Qibla from London matches reference (118.987…°)', () {
    final service = PrayerTimesService();
    final qibla = service.qibla(const Coordinates(51.5073509, -0.1277583));
    expect(qibla.degrees, closeTo(118.98724271029, 1e-6));
  });

  test('Qibla is normalized to [0, 360)', () {
    const calculator = QiblaCalculator();
    final q = calculator.direction(const Coordinates(-33.8688, 151.2093));
    expect(q.degrees, inInclusiveRange(0, 360));
  });
}
