import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit_plus/islamic_kit_plus.dart';

void main() {
  final service = PrayerTimesService();
  const london = Coordinates(51.508515, -0.1254872);
  const params = CalculationParameters(
    method: CalculationMethod.isna,
    utcOffset: Duration(hours: 1),
    timezoneName: 'Europe/London',
  );

  test('single-date envelope matches aladhan shape', () {
    final json =
        service.timings(DateTime(2014, 4, 24), london, params).toAladhanJson();

    expect(json['code'], 200);
    expect(json['status'], 'OK');

    final data = json['data'] as Map<String, dynamic>;
    final timings = data['timings'] as Map<String, dynamic>;
    expect(timings['Fajr'], '03:57');
    expect(timings['Dhuhr'], '12:59');
    expect(timings.containsKey('Firstthird'), isTrue);

    final date = data['date'] as Map<String, dynamic>;
    final gregorian = date['gregorian'] as Map<String, dynamic>;
    expect(gregorian['date'], '24-04-2014');
    expect((gregorian['month'] as Map)['number'], 4);
    expect(date['timestamp'], isA<String>());

    final hijri = date['hijri'] as Map<String, dynamic>;
    expect((hijri['weekday'] as Map).containsKey('ar'), isTrue);
    expect((hijri['month'] as Map)['days'], isA<int>());

    final meta = data['meta'] as Map<String, dynamic>;
    expect((meta['method'] as Map)['id'], 2);
    expect(meta['school'], 'STANDARD');
    expect(meta['latitudeAdjustmentMethod'], 'ANGLE_BASED');
    expect((meta['offset'] as Map).length, 9);
  });

  test('calendar timings carry the timezone suffix', () {
    final month = service.monthlyCalendar(2014, 4, london, params);
    final json = calendarAladhanJson(month);
    final data = json['data'] as List<dynamic>;
    expect(data.length, 30);
    final firstTimings =
        (data.first as Map<String, dynamic>)['timings'] as Map<String, dynamic>;
    expect(firstTimings['Fajr'], endsWith('(Europe/London)'));
  });

  test('annual calendar is keyed by month string', () {
    final year = service.annualCalendar(2014, london, params);
    final json = annualCalendarAladhanJson(year);
    final data = json['data'] as Map<String, dynamic>;
    expect(data.keys, containsAll(<String>['1', '12']));
  });

  test('methods response exposes MWL with params', () {
    final json = methodsAladhanJson();
    final data = json['data'] as Map<String, dynamic>;
    final mwl = data['MWL'] as Map<String, dynamic>;
    expect(mwl['id'], 3);
    expect((mwl['params'] as Map)['Fajr'], 18);
    expect((mwl['params'] as Map)['Isha'], 17);
  });

  test('makkah serializes Isha as "90 min"', () {
    final json = methodsAladhanJson();
    final data = json['data'] as Map<String, dynamic>;
    final makkah = data['MAKKAH'] as Map<String, dynamic>;
    expect((makkah['params'] as Map)['Isha'], '90 min');
  });
}
