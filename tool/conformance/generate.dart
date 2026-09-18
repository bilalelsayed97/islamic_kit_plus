// ignore_for_file: avoid_print
//
// Generates the cross-language conformance fixtures that the native Swift and
// Kotlin ports assert against. The Dart implementation is the reference; the
// fixtures capture its exact outputs for a broad grid of inputs.
//
// Usage (from the package root; the TZ is mandatory because a few Dart code
// paths go through local `DateTime` arithmetic):
//
//   TZ=UTC dart run tool/conformance/generate.dart [outDir]
//
// `outDir` defaults to `conformance/`. The geocoding fixtures read
// `assets/prayer_times.db`.

import 'dart:convert';
import 'dart:io';

import 'package:islamic_kit_plus/islamic_kit_plus.dart';
import 'package:islamic_kit_plus/src/infrastructure/astronomy/solar_time.dart';
import 'package:islamic_kit_plus/src/infrastructure/geocoding/data/city_dataset.dart';
import 'package:sqlite3/sqlite3.dart';

const int _schema = 1;
const String _dbPath = 'assets/prayer_times.db';

const JsonEncoder _pretty = JsonEncoder.withIndent('  ');

// -----------------------------------------------------------------------------
// Fixed inputs
// -----------------------------------------------------------------------------

class _Place {
  const _Place(this.id, this.lat, this.lng, this.offsetSeconds,
      [this.timezoneName]);
  final String id;
  final double lat;
  final double lng;
  final int offsetSeconds;
  final String? timezoneName;

  Coordinates get coordinates => Coordinates(lat, lng);
  Duration get offset => Duration(seconds: offsetSeconds);
}

const List<_Place> _matrixPlaces = <_Place>[
  _Place('london', 51.508515, -0.1254872, 0, 'Europe/London'),
  _Place('raleigh', 35.7750, -78.6336, -18000, 'America/New_York'),
  _Place('makkah', 21.4225, 39.8262, 10800, 'Asia/Riyadh'),
  _Place('cairo', 30.0444196, 31.2357116, 7200, 'Africa/Cairo'),
  _Place('karachi', 24.8614622, 67.0099388, 18000, 'Asia/Karachi'),
  _Place('jakarta', -6.2087634, 106.845599, 25200, 'Asia/Jakarta'),
  _Place('tehran', 35.6891975, 51.3889736, 12600, 'Asia/Tehran'),
  _Place('stockholm', 59.3293, 18.0686, 3600, 'Europe/Stockholm'),
  _Place('tromso', 69.6492, 18.9553, 3600, 'Europe/Oslo'),
  _Place('longyearbyen', 78.2232, 15.6469, 3600, 'Arctic/Longyearbyen'),
  _Place('sydney', -33.8688, 151.2093, 36000, 'Australia/Sydney'),
  _Place('anchorage', 61.2181, -149.9003, -32400, 'America/Anchorage'),
  _Place('kolkata', 22.5726, 88.3639, 19800, 'Asia/Kolkata'),
  _Place('stjohns', 47.5615, -52.7126, -12600, 'America/St_Johns'),
];

const _Place _kathmandu = _Place('kathmandu', 27.7172, 85.3240, 20700, 'Asia/Kathmandu');

final List<DateTime> _matrixDates = <DateTime>[
  DateTime(2024, 3, 20),
  DateTime(2024, 6, 20),
  DateTime(2024, 9, 22),
  DateTime(2024, 12, 21),
  DateTime(2014, 4, 24),
  DateTime(2015, 7, 12),
  DateTime(2026, 2, 20), // Ramadan 1447
  DateTime(2024, 2, 29),
];

const MethodParams _customParams = MethodParams(
  fajrAngle: 18,
  ishaMinutesAfterMaghrib: 90,
);

// -----------------------------------------------------------------------------
// Entry point
// -----------------------------------------------------------------------------

void main(List<String> args) {
  if (DateTime.now().timeZoneOffset != Duration.zero) {
    stderr.writeln('Run with TZ=UTC (the host time zone is '
        '${DateTime.now().timeZoneName}).');
    exit(1);
  }
  final outDir = args.isEmpty ? 'conformance' : args.first;
  Directory(outDir).createSync(recursive: true);

  final counts = <String, int>{};
  void emit(String name, Object json, {bool pretty = true}) {
    final text = pretty ? _pretty.convert(json) : jsonEncode(json);
    File('$outDir/$name').writeAsStringSync('$text\n');
    print('wrote $outDir/$name (${text.length} chars)');
  }

  final service = PrayerTimesService();

  final matrix = _timingsMatrix(service);
  counts['timings_matrix'] = matrix.length;
  emit('timings_matrix.json', {'cases': matrix}, pretty: false);

  final detail = _timingsDetail(service);
  counts['timings_detail'] = detail.length;
  emit('timings_detail.json', {'cases': detail});

  final hijri = _hijri();
  counts['hijri_fromGregorian'] = (hijri['fromGregorian'] as List).length;
  counts['hijri_toGregorian'] = (hijri['toGregorian'] as List).length;
  counts['hijri_daily'] =
      ((hijri['daily'] as Map<String, Object?>)['rows'] as List).length;
  emit('hijri.json', hijri, pretty: false);

  final qibla = _qibla();
  counts['qibla'] = qibla.length;
  emit('qibla.json', {'cases': qibla});

  final next = _nextPrayer(service);
  counts['next_prayer'] = next.length;
  emit('next_prayer.json', {'cases': next});

  final calendars = _calendars(service);
  counts['calendars'] = calendars.length;
  emit('calendars.json', {'cases': calendars}, pretty: false);

  emit('methods.json', {
    'json': jsonEncode(methodsAladhanJson()),
    'data': methodsAladhanJson(),
  });

  emit('aladhan.json', _aladhan(service));

  emit('localization.json', _localization());

  final moon = _moonsighting();
  counts['moonsighting'] = moon.length;
  emit('moonsighting.json', {'cases': moon}, pretty: false);

  final curated = _geocoderCurated();
  counts['geocoder_curated'] = curated.length;
  emit('geocoder_curated.json', {'cases': curated});

  final sqliteGeo = _geocoderSqlite();
  counts['geocoder_sqlite'] = sqliteGeo.length;
  emit('geocoder_sqlite.json', {'cases': sqliteGeo});

  emit('directory.json', _directory());

  emit('manifest.json', {
    'schema': _schema,
    'generator': 'islamic_kit_plus tool/conformance/generate.dart',
    'packageVersion': _packageVersion(),
    'dartSdk': Platform.version.split(' ').first,
    'gitSha': _gitSha(),
    'tz': 'UTC',
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'counts': counts,
  });
}

String _packageVersion() {
  final match = RegExp(r'^version:\s*(\S+)', multiLine: true)
      .firstMatch(File('pubspec.yaml').readAsStringSync());
  return match?.group(1) ?? 'unknown';
}

String _gitSha() {
  final result = Process.runSync('git', ['rev-parse', 'HEAD']);
  return result.exitCode == 0 ? (result.stdout as String).trim() : 'unknown';
}

// -----------------------------------------------------------------------------
// Serialization helpers
// -----------------------------------------------------------------------------

String _d(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

String _two(int n) => n < 10 ? '0$n' : '$n';

double? _finite(double v) => v.isNaN || v.isInfinite ? null : v;

Map<String, Object?> _methodParamsJson(MethodParams p) => <String, Object?>{
      'fajrAngle': p.fajrAngle,
      'ishaAngle': p.ishaAngle,
      'ishaMinutesAfterMaghrib': p.ishaMinutesAfterMaghrib,
      'ramadanIshaMinutesAfterMaghrib': p.ramadanIshaMinutesAfterMaghrib,
      'maghribAngle': p.maghribAngle,
      'maghribMinutesAfterSunset': p.maghribMinutesAfterSunset,
      'adjustments': <String, int>{
        'fajr': p.adjustments.fajr,
        'sunrise': p.adjustments.sunrise,
        'dhuhr': p.adjustments.dhuhr,
        'asr': p.adjustments.asr,
        'maghrib': p.adjustments.maghrib,
        'isha': p.adjustments.isha,
      },
      'midnightMode': p.midnightMode?.metaValue,
      'location': p.location == null
          ? null
          : <String, double>{
              'lat': p.location!.latitude,
              'lng': p.location!.longitude,
            },
    };

Map<String, Object?> _paramsJson(CalculationParameters p) => <String, Object?>{
      'method': p.method.code,
      'customMethod':
          p.customMethod == null ? null : _methodParamsJson(p.customMethod!),
      'school': p.school.metaValue,
      'asrShadowFactor': p.asrShadowFactor,
      'midnightMode': p.midnightMode?.metaValue,
      'highLatitudeRule': p.highLatitudeRule.metaValue,
      'utcOffsetSeconds': p.utcOffset.inSeconds,
      'elevation': p.elevation,
      'shafaq': p.shafaq.code,
      'tune': p.tune.toCsv(),
      'imsakMinutes': p.imsakMinutes,
      'dhuhrMinutes': p.dhuhrMinutes,
      'calendarMethod': p.calendarMethod.code,
      'timezoneName': p.timezoneName,
    };

Map<String, double?> _rawJson(PrayerResult r) => <String, double?>{
      for (final p in Prayer.values) p.key: r.timings.raw[p],
    };

Map<String, Object?> _hijriJson(HijriDate h) => <String, Object?>{
      'hijri': h.formatted,
      'day': h.day,
      'month': h.month,
      'year': h.year,
      'monthLength': h.monthLength,
      'weekdayEn': h.weekdayEn,
      'weekdayAr': h.weekdayAr,
      'monthEn': h.monthEn,
      'monthAr': h.monthAr,
      'method': h.method.code,
      'holidays': h.holidays,
    };

Map<String, Object?> _caseJson(
  String id,
  DateTime date,
  _Place place,
  CalculationParameters params,
  PrayerResult r,
) =>
    <String, Object?>{
      'id': id,
      'date': _d(date),
      'lat': place.lat,
      'lng': place.lng,
      'params': _paramsJson(params),
      'raw': _rawJson(r),
    };

// -----------------------------------------------------------------------------
// Timings
// -----------------------------------------------------------------------------

List<Map<String, Object?>> _timingsMatrix(PrayerTimesService service) {
  final out = <Map<String, Object?>>[];
  for (final place in _matrixPlaces) {
    for (final date in _matrixDates) {
      for (final method in CalculationMethod.values) {
        final params = CalculationParameters(
          method: method,
          customMethod: method == CalculationMethod.custom ? _customParams : null,
          utcOffset: place.offset,
        );
        final r = service.timings(date, place.coordinates, params);
        out.add(_caseJson(
            '${place.id}/${_d(date)}/${method.code}', date, place, params, r));
      }
    }
  }
  return out;
}

class _Detail {
  const _Detail(this.label, this.place, this.date, this.params);
  final String label;
  final _Place place;
  final DateTime date;
  final CalculationParameters params;
}

List<_Detail> _detailCases() {
  const london = _Place('london', 51.508515, -0.1254872, 3600, 'Europe/London');
  const raleigh = _Place('raleigh', 35.7750, -78.6336, -14400);
  final makkah = _matrixPlaces[2];
  final stockholm = _matrixPlaces[7];
  final tromso = _matrixPlaces[8];
  final longyearbyen = _matrixPlaces[9];
  final sydney = _matrixPlaces[10];
  final kolkata = _matrixPlaces[12];
  final stjohns = _matrixPlaces[13];
  final apr24 = DateTime(2014, 4, 24);
  final jun21 = DateTime(2024, 6, 21);
  final dec15 = DateTime(2024, 12, 15);

  final cases = <_Detail>[
    _Detail('raleigh-isna-hanafi', raleigh, DateTime(2015, 7, 12),
        CalculationParameters(method: CalculationMethod.isna, school: AsrSchool.hanafi, utcOffset: raleigh.offset)),
    _Detail('raleigh-isna-standard', raleigh, DateTime(2015, 7, 12),
        CalculationParameters(method: CalculationMethod.isna, utcOffset: raleigh.offset)),
    _Detail('london-isna', london, apr24,
        CalculationParameters(method: CalculationMethod.isna, utcOffset: london.offset, timezoneName: 'Europe/London')),
    _Detail('london-isna-midnight-standard', london, apr24,
        CalculationParameters(method: CalculationMethod.isna, utcOffset: london.offset, midnightMode: MidnightMode.standard)),
    _Detail('london-isna-midnight-jafari', london, apr24,
        CalculationParameters(method: CalculationMethod.isna, utcOffset: london.offset, midnightMode: MidnightMode.jafari)),
    _Detail('london-tune', london, apr24,
        CalculationParameters(method: CalculationMethod.isna, utcOffset: london.offset, tune: const Tune(imsak: 5, fajr: 3, sunrise: 5, dhuhr: 7, asr: 9, maghrib: -1, sunset: 0, isha: 8, midnight: -6))),
    _Detail('london-imsak-dhuhr-minutes', london, apr24,
        CalculationParameters(method: CalculationMethod.mwl, utcOffset: london.offset, imsakMinutes: 15, dhuhrMinutes: 2)),
    _Detail('london-elevation-1000', london, apr24,
        CalculationParameters(method: CalculationMethod.mwl, utcOffset: london.offset, elevation: 1000)),
    _Detail('london-shadow-factor-1.5', london, apr24,
        CalculationParameters(method: CalculationMethod.mwl, utcOffset: london.offset, asrShadowFactor: 1.5)),
    _Detail('london-custom-angles', london, apr24,
        const CalculationParameters(method: CalculationMethod.custom, customMethod: MethodParams(fajrAngle: 16, ishaAngle: 14), utcOffset: Duration(hours: 1))),
    _Detail('london-custom-intervals', london, apr24,
        const CalculationParameters(method: CalculationMethod.custom, customMethod: MethodParams(fajrAngle: 18, ishaMinutesAfterMaghrib: 90, maghribMinutesAfterSunset: 3), utcOffset: Duration(hours: 1))),
    _Detail('london-custom-maghrib-angle-jafari', london, apr24,
        const CalculationParameters(method: CalculationMethod.custom, customMethod: MethodParams(fajrAngle: 17.7, ishaAngle: 14, maghribAngle: 4.5, midnightMode: MidnightMode.jafari), utcOffset: Duration(hours: 1))),
    _Detail('london-custom-null-uses-default', london, apr24,
        const CalculationParameters(method: CalculationMethod.custom, utcOffset: Duration(hours: 1))),
    _Detail('london-rollover-north-70-west', const _Place('n70w10', 70, -10, 3600), apr24,
        const CalculationParameters(method: CalculationMethod.isna, utcOffset: Duration(hours: 1))),
    _Detail('london-rollover-north-70-east', const _Place('n70e40', 70, 40, 3600), apr24,
        const CalculationParameters(method: CalculationMethod.isna, utcOffset: Duration(hours: 1))),
    _Detail('makkah-ramadan', makkah, DateTime(2026, 2, 20),
        CalculationParameters(method: CalculationMethod.makkah, utcOffset: makkah.offset)),
    _Detail('makkah-not-ramadan', makkah, DateTime(2026, 4, 20),
        CalculationParameters(method: CalculationMethod.makkah, utcOffset: makkah.offset)),
    _Detail('makkah-qatar-in-ramadan', makkah, DateTime(2026, 2, 20),
        CalculationParameters(method: CalculationMethod.qatar, utcOffset: makkah.offset)),
    _Detail('longyearbyen-polar-night', longyearbyen, dec15,
        CalculationParameters(utcOffset: longyearbyen.offset)),
    _Detail('longyearbyen-polar-day', longyearbyen, jun21,
        CalculationParameters(utcOffset: longyearbyen.offset)),
    _Detail('siberia-karachi-jan', const _Place('sib', 67.104732, 67.104732, 18000), DateTime(2018, 1, 19),
        const CalculationParameters(method: CalculationMethod.karachi, utcOffset: Duration(hours: 5))),
    _Detail('kolkata-half-hour', kolkata, apr24,
        CalculationParameters(method: CalculationMethod.karachi, school: AsrSchool.hanafi, utcOffset: kolkata.offset, timezoneName: 'Asia/Kolkata')),
    _Detail('kathmandu-quarter-hour', _kathmandu, apr24,
        CalculationParameters(utcOffset: _kathmandu.offset)),
    _Detail('stjohns-negative-half-hour', stjohns, apr24,
        CalculationParameters(method: CalculationMethod.isna, utcOffset: stjohns.offset)),
    _Detail('sydney-southern', sydney, jun21,
        CalculationParameters(method: CalculationMethod.mwl, utcOffset: sydney.offset)),
    _Detail('uaq-table-start', makkah, DateTime(1937, 3, 14),
        CalculationParameters(method: CalculationMethod.makkah, utcOffset: makkah.offset, calendarMethod: CalendarMethod.uaq)),
    _Detail('uaq-table-end', makkah, DateTime(2077, 11, 16),
        CalculationParameters(method: CalculationMethod.makkah, utcOffset: makkah.offset, calendarMethod: CalendarMethod.uaq)),
    _Detail('diyanet-table-start', london, DateTime(1900, 5, 1),
        const CalculationParameters(utcOffset: Duration.zero, calendarMethod: CalendarMethod.diyanet)),
    _Detail('mathematical-1850', london, DateTime(1850, 1, 1),
        const CalculationParameters(utcOffset: Duration.zero, calendarMethod: CalendarMethod.mathematical)),
    _Detail('mathematical-2150', london, DateTime(2150, 6, 1),
        const CalculationParameters(utcOffset: Duration.zero, calendarMethod: CalendarMethod.mathematical)),
  ];

  // Every high-latitude rule x midnight mode at Stockholm on the solstice.
  for (final rule in HighLatitudeRule.values) {
    for (final mode in <MidnightMode?>[null, ...MidnightMode.values]) {
      cases.add(_Detail(
        'stockholm-${rule.name}-${mode?.name ?? 'null'}',
        stockholm,
        jun21,
        CalculationParameters(
          utcOffset: const Duration(hours: 2),
          highLatitudeRule: rule,
          midnightMode: mode,
        ),
      ));
    }
  }
  // Moonsighting with each shafaq, below and above 55 degrees.
  for (final shafaq in Shafaq.values) {
    cases.add(_Detail(
      'london-moonsighting-${shafaq.code}',
      london,
      apr24,
      CalculationParameters(
        method: CalculationMethod.moonsighting,
        utcOffset: london.offset,
        shafaq: shafaq,
      ),
    ));
    cases.add(_Detail(
      'tromso-moonsighting-${shafaq.code}',
      tromso,
      DateTime(2024, 4, 24),
      CalculationParameters(
        method: CalculationMethod.moonsighting,
        utcOffset: tromso.offset,
        shafaq: shafaq,
      ),
    ));
    cases.add(_Detail(
      'sydney-moonsighting-${shafaq.code}',
      sydney,
      DateTime(2024, 10, 10),
      CalculationParameters(
        method: CalculationMethod.moonsighting,
        utcOffset: sydney.offset,
        shafaq: shafaq,
      ),
    ));
  }
  // Every calendar method on the same day.
  for (final cm in CalendarMethod.values) {
    cases.add(_Detail(
      'cairo-calendar-${cm.code}',
      _matrixPlaces[3],
      DateTime(2025, 2, 14),
      CalculationParameters(
        method: CalculationMethod.egypt,
        utcOffset: const Duration(hours: 2),
        calendarMethod: cm,
      ),
    ));
  }
  // A Hijri holiday day (Eid al-Fitr 1445 = 2024-04-10 in UAQ) and Ashura.
  cases.add(_Detail('cairo-eid-al-fitr-1445', _matrixPlaces[3], DateTime(2024, 4, 10),
      const CalculationParameters(method: CalculationMethod.egypt, utcOffset: Duration(hours: 2))));
  cases.add(_Detail('cairo-ashura-1446', _matrixPlaces[3], DateTime(2024, 7, 16),
      const CalculationParameters(method: CalculationMethod.egypt, utcOffset: Duration(hours: 2))));
  // An HJCoSA sighting override day.
  cases.add(_Detail('makkah-hjcosa-override-2018-05-17', makkah, DateTime(2018, 5, 17),
      CalculationParameters(method: CalculationMethod.makkah, utcOffset: makkah.offset)));
  return cases;
}

List<Map<String, Object?>> _timingsDetail(PrayerTimesService service) {
  final out = <Map<String, Object?>>[];
  for (final c in _detailCases()) {
    final r = service.timings(c.date, c.place.coordinates, c.params);
    final solar = SolarTime(
      year: c.date.year,
      month: c.date.month,
      day: c.date.day,
      coordinates: c.place.coordinates,
      elevation: c.params.elevation,
    );
    final json = _caseJson(c.label, c.date, c.place, c.params, r);
    json['solar'] = <String, double?>{
      'transit': _finite(solar.transit),
      'sunrise': _finite(solar.sunrise),
      'sunset': _finite(solar.sunset),
      'asrStandard': _finite(solar.afternoon(1)),
      'asrHanafi': _finite(solar.afternoon(2)),
    };
    json['formatted'] = <String, Map<String, String>>{
      for (final f in TimeFormat.values)
        f.code: <String, String>{
          for (final p in Prayer.values) p.key: r.formatted(p, f),
        },
    };
    json['epochMillis'] = <String, int?>{
      for (final p in Prayer.values)
        p.key: r.time(p).toUtc()?.millisecondsSinceEpoch,
    };
    json['date'] = <String, Object?>{
      'readable': r.date.readable,
      'timestamp': r.date.timestamp,
      'gregorianWeekdayEn': r.date.gregorian.weekdayEn,
      'gregorianMonthEn': r.date.gregorian.monthEn,
      'gregorian': r.date.gregorian.formatted,
      ..._hijriJson(r.date.hijri),
    };
    json['meta'] = <String, Object?>{
      'timezone': r.meta.timezone,
      'methodId': r.meta.method.id,
      'school': r.meta.school.metaValue,
      'midnightMode': r.meta.midnightMode.metaValue,
      'latitudeAdjustmentMethod': r.meta.latitudeAdjustmentMethod.metaValue,
      'shafaq': r.meta.shafaq.code,
      'offsets': <String, int>{
        for (final e in r.meta.offsets.entries) e.key.key: e.value,
      },
    };
    json['aladhanJson'] = jsonEncode(r.toAladhanJson());
    json['aladhanJsonIso'] = jsonEncode(r.toAladhanJson(format: TimeFormat.iso8601));
    json['aladhanJson12h'] = jsonEncode(r.toAladhanJson(format: TimeFormat.h12));
    out.add(json);
  }
  return out;
}

// -----------------------------------------------------------------------------
// Hijri
// -----------------------------------------------------------------------------

Map<String, Object?> _hijri() {
  const factory = HijriConverterFactory();
  final from = <Map<String, Object?>>[];
  final to = <Map<String, Object?>>[];

  void addFrom(CalendarMethod m, DateTime d, {int adjustment = 0}) {
    final converter = factory.create(m);
    final entry = <String, Object?>{
      'method': m.code,
      'date': _d(d),
      if (adjustment != 0) 'adjustment': adjustment,
    };
    try {
      entry.addAll(_hijriJson(converter.fromGregorian(d, adjustment: adjustment)));
    } on ArgumentError {
      entry['error'] = 'ArgumentError';
    }
    from.add(entry);
  }

  void addTo(CalendarMethod m, int y, int mo, int d, {int adjustment = 0}) {
    final converter = factory.create(m);
    final entry = <String, Object?>{
      'method': m.code,
      'hijri': '${_two(d)}-${_two(mo)}-${y.toString().padLeft(4, '0')}',
      if (adjustment != 0) 'adjustment': adjustment,
    };
    try {
      entry['date'] = _d(converter.toGregorian(y, mo, d, adjustment: adjustment));
    } on ArgumentError {
      entry['error'] = 'ArgumentError';
    }
    to.add(entry);
  }

  final ranges = <CalendarMethod, (DateTime, DateTime)>{
    CalendarMethod.hjcosa: (DateTime(1937, 3, 14), DateTime(2077, 11, 16)),
    CalendarMethod.uaq: (DateTime(1937, 3, 14), DateTime(2077, 11, 16)),
    CalendarMethod.diyanet: (DateTime(1900, 5, 1), DateTime(2028, 1, 26)),
    CalendarMethod.mathematical: (DateTime(1900, 1, 1), DateTime(2100, 12, 31)),
  };

  // Every day of 2010..2030 (clipped to the method's range) in a compact form
  // (method code, date, hijri `dd-mm-yyyy`, month length); names and holidays
  // are covered by the full entries below.
  final daily = <List<Object>>[];
  for (final m in CalendarMethod.values) {
    final converter = factory.create(m);
    final (_, rangeEnd) = ranges[m]!;
    final sweepEnd = rangeEnd.isBefore(DateTime(2030, 12, 31))
        ? rangeEnd
        : DateTime(2030, 12, 31);
    for (var d = DateTime(2010, 1, 1);
        !d.isAfter(sweepEnd);
        d = DateTime(d.year, d.month, d.day + 1)) {
      final h = converter.fromGregorian(d);
      daily.add(<Object>[m.code, _d(d), h.formatted, h.monthLength]);
    }
  }

  for (final m in CalendarMethod.values) {
    // Every 29th day across the method's whole range.
    final (start, end) = ranges[m]!;
    for (var d = start; !d.isAfter(end); d = DateTime(d.year, d.month, d.day + 29)) {
      addFrom(m, d);
    }
    // Range edges and one day beyond.
    addFrom(m, DateTime(start.year, start.month, start.day - 1));
    addFrom(m, start);
    addFrom(m, end);
    addFrom(m, DateTime(end.year, end.month, end.day + 1));
    addFrom(m, DateTime(1800, 1, 1));
    addFrom(m, DateTime(2100, 1, 1));
    // toGregorian: the 1st and 15th of every Hijri month across the range.
    final (hyStart, hyEnd) = m == CalendarMethod.diyanet
        ? (1318, 1449)
        : m == CalendarMethod.mathematical
            ? (1200, 1600)
            : (1356, 1500);
    for (var y = hyStart; y <= hyEnd; y++) {
      for (var mo = 1; mo <= 12; mo++) {
        addTo(m, y, mo, 1);
        if (y % 5 == 0) addTo(m, y, mo, 15);
      }
    }
    addTo(m, 1200, 8, 15);
    addTo(m, 1500, 12, 30);
    addTo(m, 1501, 1, 1);
    addTo(m, 1449, 8, 29);
    addTo(m, 1449, 9, 1);
  }

  // HJCoSA sighting overrides and their neighbours, in every method.
  const sightingDates = <String>[
    '27-10-2003', '13-11-2004', '11-01-2005', '20-01-2005', '23-09-2006',
    '21-12-2006', '30-12-2006', '12-10-2007', '10-12-2007', '19-12-2007',
    '30-09-2008', '27-11-2011', '10-07-2013', '05-11-2013', '29-06-2014',
    '15-09-2015', '24-09-2015', '15-10-2015', '03-09-2016', '12-09-2016',
    '17-05-2018', '10-08-2021',
  ];
  for (final s in sightingDates) {
    final parts = s.split('-').map(int.parse).toList();
    final d = DateTime(parts[2], parts[1], parts[0]);
    for (final m in CalendarMethod.values) {
      for (var k = -2; k <= 2; k++) {
        addFrom(m, DateTime(d.year, d.month, d.day + k));
      }
    }
  }
  // Mathematical adjustments.
  for (final adj in <int>[-2, -1, 1, 2]) {
    addFrom(CalendarMethod.mathematical, DateTime(2025, 2, 14), adjustment: adj);
    addTo(CalendarMethod.mathematical, 1446, 8, 15, adjustment: adj);
    // Table methods ignore the adjustment on fromGregorian but apply it on
    // toGregorian (Dart behaviour, reproduced as-is).
    addFrom(CalendarMethod.uaq, DateTime(2025, 2, 14), adjustment: adj);
    addTo(CalendarMethod.uaq, 1446, 8, 15, adjustment: adj);
    addTo(CalendarMethod.hjcosa, 1439, 9, 1, adjustment: adj);
  }
  return <String, Object?>{
    'fromGregorian': from,
    'toGregorian': to,
    'daily': <String, Object?>{
      'columns': <String>['method', 'date', 'hijri', 'monthLength'],
      'rows': daily,
    },
  };
}

// -----------------------------------------------------------------------------
// Qibla
// -----------------------------------------------------------------------------

List<Map<String, Object?>> _qibla() {
  const calc = QiblaCalculator();
  const points = <List<double>>[
    [51.5073509, -0.1277583], [-33.8688, 151.2093], [21.422517, 39.826166],
    [21.4225, 39.8262], [0, 0], [90, 0], [-90, 0], [0, 180], [0, -180],
    [40.7128, -74.0060], [35.6895, 139.6917], [-23.5505, -46.6333],
    [55.7558, 37.6173], [30.0444, 31.2357], [24.7136, 46.6753],
    [-1.2921, 36.8219], [64.1466, -21.9426], [-34.6037, -58.3816],
    [1.3521, 103.8198], [19.4326, -99.1332], [41.0082, 28.9784],
    [33.6844, 73.0479], [23.8103, 90.4125], [-6.2088, 106.8456],
    [3.1390, 101.6869], [48.8566, 2.3522], [52.5200, 13.4050],
    [43.6532, -79.3832], [-26.2041, 28.0473], [25.2048, 55.2708],
    [39.9042, 116.4074], [-37.8136, 144.9631], [-41.2865, 174.7762],
    [21.3099, -157.8581], [61.2181, -149.9003], [78.2232, 15.6469],
    [-54.8019, -68.3030], [27.7172, 85.3240], [35.6892, 51.3890],
    [-4.4419, 15.2663], [14.5995, 120.9842], [37.7749, -122.4194],
    [21.422517, 219.826166], [-21.422517, -140.173834], [60, 39.826166],
  ];
  return <Map<String, Object?>>[
    for (final p in points)
      <String, Object?>{
        'lat': p[0],
        'lng': p[1],
        'degrees': calc.direction(Coordinates(p[0], p[1])).degrees,
      },
  ];
}

// -----------------------------------------------------------------------------
// Next prayer
// -----------------------------------------------------------------------------

List<Map<String, Object?>> _nextPrayer(PrayerTimesService service) {
  final out = <Map<String, Object?>>[];
  final places = <_Place>[
    const _Place('london', 51.508515, -0.1254872, 3600),
    _matrixPlaces[2],
    _matrixPlaces[7],
    _matrixPlaces[10],
    _matrixPlaces[12],
  ];
  final times = <List<int>>[
    [0, 30, 0], [4, 0, 0], [5, 0, 0], [9, 0, 0], [13, 30, 0], [17, 0, 0],
    [21, 0, 0], [23, 30, 0], [23, 59, 59],
  ];
  for (final place in places) {
    for (final date in <DateTime>[DateTime(2014, 4, 24), DateTime(2024, 12, 21)]) {
      for (final t in times) {
        final from = DateTime(date.year, date.month, date.day, t[0], t[1], t[2]);
        final params = CalculationParameters(
          method: CalculationMethod.isna,
          utcOffset: place.offset,
        );
        final next = service.nextPrayer(from, place.coordinates, params);
        out.add(<String, Object?>{
          'id': '${place.id}/${_d(date)}/${_two(t[0])}:${_two(t[1])}:${_two(t[2])}',
          'from': '${_d(date)}T${_two(t[0])}:${_two(t[1])}:${_two(t[2])}',
          'lat': place.lat,
          'lng': place.lng,
          'params': _paramsJson(params),
          'prayer': next.prayer.key,
          'hours': next.time.hours,
          'formatted': next.time.format(),
          'onDate': _d(next.onDate),
        });
      }
    }
  }
  return out;
}

// -----------------------------------------------------------------------------
// Calendars
// -----------------------------------------------------------------------------

List<Map<String, Object?>> _calendars(PrayerTimesService service) {
  const london = _Place('london', 51.508515, -0.1254872, 3600, 'Europe/London');
  final makkah = _matrixPlaces[2];
  final londonParams = CalculationParameters(
    method: CalculationMethod.isna,
    utcOffset: london.offset,
    timezoneName: 'Europe/London',
  );
  final makkahParams = CalculationParameters(
    method: CalculationMethod.makkah,
    utcOffset: makkah.offset,
  );
  final out = <Map<String, Object?>>[];

  Map<String, Object?> day(PrayerResult r) => <String, Object?>{
        'date': r.date.gregorian.formatted,
        'hijri': r.date.hijri.formatted,
        'raw': _rawJson(r),
      };

  final monthly = service.monthlyCalendar(2014, 4, london.coordinates, londonParams);
  out.add(<String, Object?>{
    'kind': 'monthly',
    'year': 2014,
    'month': 4,
    'lat': london.lat,
    'lng': london.lng,
    'params': _paramsJson(londonParams),
    'days': monthly.map(day).toList(),
  });
  final annual = service.annualCalendar(2014, london.coordinates, londonParams);
  out.add(<String, Object?>{
    'kind': 'annual',
    'year': 2014,
    'lat': london.lat,
    'lng': london.lng,
    'params': _paramsJson(londonParams),
    'months': <String, Object?>{
      for (final e in annual.entries)
        '${e.key}': <String, Object?>{
          'count': e.value.length,
          'first': day(e.value.first),
          'last': day(e.value.last),
        },
    },
  });
  final range = service.rangeCalendar(
      DateTime(2014, 1, 1), DateTime(2014, 3, 31), london.coordinates, londonParams);
  out.add(<String, Object?>{
    'kind': 'range',
    'start': '2014-01-01',
    'end': '2014-03-31',
    'lat': london.lat,
    'lng': london.lng,
    'params': _paramsJson(londonParams),
    'count': range.length,
    'first': day(range.first),
    'last': day(range.last),
  });
  for (final bad in <List<String>>[
    ['2014-01-01', '2015-01-01'],
    ['2014-03-31', '2014-01-01'],
  ]) {
    out.add(<String, Object?>{
      'kind': 'rangeError',
      'start': bad[0],
      'end': bad[1],
      'lat': london.lat,
      'lng': london.lng,
      'params': _paramsJson(londonParams),
      'error': 'ArgumentError',
    });
  }
  for (final cm in CalendarMethod.values) {
    final params = makkahParams.copyWith(calendarMethod: cm);
    final hijriMonth = service.monthlyHijriCalendar(1446, 9, makkah.coordinates, params);
    out.add(<String, Object?>{
      'kind': 'hijriMonthly',
      'hijriYear': 1446,
      'hijriMonth': 9,
      'lat': makkah.lat,
      'lng': makkah.lng,
      'params': _paramsJson(params),
      'days': hijriMonth.map(day).toList(),
    });
  }
  final hijriAnnual = service.annualHijriCalendar(1446, makkah.coordinates, makkahParams);
  out.add(<String, Object?>{
    'kind': 'hijriAnnual',
    'hijriYear': 1446,
    'lat': makkah.lat,
    'lng': makkah.lng,
    'params': _paramsJson(makkahParams),
    'months': <String, Object?>{
      for (final e in hijriAnnual.entries)
        '${e.key}': <String, Object?>{
          'count': e.value.length,
          'first': day(e.value.first),
          'last': day(e.value.last),
        },
    },
  });
  return out;
}

// -----------------------------------------------------------------------------
// aladhan envelopes
// -----------------------------------------------------------------------------

Map<String, Object?> _aladhan(PrayerTimesService service) {
  const london = _Place('london', 51.508515, -0.1254872, 3600, 'Europe/London');
  final params = CalculationParameters(
    method: CalculationMethod.isna,
    utcOffset: london.offset,
    timezoneName: 'Europe/London',
  );
  final month = service.monthlyCalendar(2014, 4, london.coordinates, params);
  final year = service.annualCalendar(2014, london.coordinates, params);
  final day = service.timings(DateTime(2014, 4, 24), london.coordinates, params);
  final qibla = service.qibla(const Coordinates(51.5073509, -0.1277583));
  return <String, Object?>{
    'input': <String, Object?>{
      'lat': london.lat,
      'lng': london.lng,
      'params': _paramsJson(params),
      'year': 2014,
      'month': 4,
      'day': '2014-04-24',
      'nextPrayer': 'Asr',
      'qibla': <String, double>{'lat': 51.5073509, 'lng': -0.1277583},
    },
    'calendar': jsonEncode(calendarAladhanJson(month)),
    'calendarIso': jsonEncode(calendarAladhanJson(month, format: TimeFormat.iso8601)),
    'annual': jsonEncode(annualCalendarAladhanJson(year)),
    'nextPrayer': jsonEncode(nextPrayerAladhanJson(day, Prayer.asr)),
    'qibla': jsonEncode(qiblaAladhanJson(qibla)),
    'methods': jsonEncode(methodsAladhanJson()),
  };
}

// -----------------------------------------------------------------------------
// Localization / enum metadata
// -----------------------------------------------------------------------------

Map<String, Object?> _localization() {
  Map<String, Object?> l10n(String name, String Function(Language) title,
          String Function(Language) description) =>
      <String, Object?>{
        'name': name,
        'titleEn': title(Language.en),
        'titleAr': title(Language.ar),
        'descriptionEn': description(Language.en),
        'descriptionAr': description(Language.ar),
      };
  Map<String, Object?> names(Map<int, LocalizedName> table) => <String, Object?>{
        for (final e in table.entries)
          '${e.key}': <String, String>{'en': e.value.en, 'ar': e.value.ar},
      };
  return <String, Object?>{
    'calculationMethods': <Map<String, Object?>>[
      for (final m in CalculationMethod.values)
        <String, Object?>{
          ...l10n(m.name, m.title, m.description),
          'id': m.id,
          'code': m.code,
          'methodName': m.methodName,
          'usesMoonsighting': m.usesMoonsighting,
          'isAladhanMethod': m.isAladhanMethod,
          'params': _methodParamsJson(m.params),
        },
    ],
    'asrSchools': <Map<String, Object?>>[
      for (final v in AsrSchool.values)
        <String, Object?>{
          ...l10n(v.name, v.title, v.description),
          'aladhanId': v.aladhanId,
          'metaValue': v.metaValue,
          'shadowFactor': v.shadowFactor,
        },
    ],
    'midnightModes': <Map<String, Object?>>[
      for (final v in MidnightMode.values)
        <String, Object?>{
          ...l10n(v.name, v.title, v.description),
          'aladhanId': v.aladhanId,
          'metaValue': v.metaValue,
        },
    ],
    'highLatitudeRules': <Map<String, Object?>>[
      for (final v in HighLatitudeRule.values)
        <String, Object?>{
          ...l10n(v.name, v.title, v.description),
          'aladhanId': v.aladhanId,
          'metaValue': v.metaValue,
        },
    ],
    'shafaqs': <Map<String, Object?>>[
      for (final v in Shafaq.values)
        <String, Object?>{...l10n(v.name, v.title, v.description), 'code': v.code},
    ],
    'calendarMethods': <Map<String, Object?>>[
      for (final v in CalendarMethod.values)
        <String, Object?>{...l10n(v.name, v.title, v.description), 'code': v.code},
    ],
    'timeFormats': <Map<String, Object?>>[
      for (final v in TimeFormat.values)
        <String, Object?>{...l10n(v.name, v.title, v.description), 'code': v.code},
    ],
    'prayers': <Map<String, Object?>>[
      for (final v in Prayer.values)
        <String, Object?>{
          ...l10n(v.name, v.title, v.description),
          'key': v.key,
          'nameEn': v.nameEn,
          'nameAr': v.nameAr,
        },
    ],
    'languages': <Map<String, Object?>>[
      for (final v in Language.values) l10n(v.name, v.title, v.description),
    ],
    'localizer': <String, Object?>{
      'islamicMonths': names(Localizer.islamicMonths),
      'hijriWeekdays': names(Localizer.hijriWeekdays),
      'gregorianMonths': names(Localizer.gregorianMonths),
      'gregorianWeekdays': names(Localizer.gregorianWeekdays),
      'monthAbbrEn': Localizer.monthAbbrEn,
    },
    'fallbacks': <String, Object?>{
      'calculationMethodFromId(-1)': CalculationMethod.fromId(-1).code,
      'calculationMethodFromCode(NOPE)': CalculationMethod.fromCode('NOPE').code,
      'asrSchoolFromAladhanId(9)': AsrSchool.fromAladhanId(9).metaValue,
      'midnightModeFromAladhanId(9)': MidnightMode.fromAladhanId(9).metaValue,
      'highLatitudeRuleFromAladhanId(9)': HighLatitudeRule.fromAladhanId(9).metaValue,
      'shafaqFromCode(x)': Shafaq.fromCode('x').code,
      'calendarMethodFromCode(x)': CalendarMethod.fromCode('x').code,
    },
    'locationDefaults': <String, Object?>{
      for (final iso in kIsoToCountryId.keys.toList()..sort())
        iso: <String, String>{
          'method': LocationDefaults.methodForCountry(iso).code,
          'school': LocationDefaults.schoolForCountry(iso).metaValue,
        },
      'XX': <String, String>{
        'method': LocationDefaults.methodForCountry('XX').code,
        'school': LocationDefaults.schoolForCountry('XX').metaValue,
      },
      'gb': <String, String>{
        'method': LocationDefaults.methodForCountry('gb').code,
        'school': LocationDefaults.schoolForCountry('gb').metaValue,
      },
    },
    'bundledMethodMap': <String, Object?>{
      for (final id in BundledMethodMap.knownIds)
        '$id': BundledMethodMap.methodForBundledId(id)!.code,
    },
  };
}

// -----------------------------------------------------------------------------
// Moonsighting twilight
// -----------------------------------------------------------------------------

List<Map<String, Object?>> _moonsighting() {
  const twilight = MoonsightingTwilight();
  final out = <Map<String, Object?>>[];
  final latitudes = <double>[-60, -35, -10, 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70];
  for (final year in <int>[2023, 2024]) {
    for (var doy = 1; doy <= 366; doy += 10) {
      final date = DateTime(year, 1, doy);
      if (date.year != year) continue;
      for (final lat in latitudes) {
        out.add(<String, Object?>{
          'date': _d(date),
          'lat': lat,
          'fajrSeconds': twilight.fajrSecondsBeforeSunrise(date, lat),
          'ishaSeconds': <String, int>{
            for (final s in Shafaq.values)
              s.code: twilight.ishaSecondsAfterSunset(date, lat, s),
          },
        });
      }
    }
  }
  return out;
}

// -----------------------------------------------------------------------------
// Geocoders (scoring re-implemented here only to flag tie-free first results)
// -----------------------------------------------------------------------------

String _normalize(String s) =>
    s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

List<String> _candidates(String query) {
  final full = _normalize(query);
  if (full.isEmpty) return const <String>[];
  final parts = <String>[full];
  for (final seg in query.split(',')) {
    final n = _normalize(seg);
    if (n.isNotEmpty && !parts.contains(n)) parts.add(n);
  }
  return parts;
}

int? _score(String name, List<String> candidates) {
  int? best;
  for (final c in candidates) {
    int? s;
    if (name == c) {
      s = 0;
    } else if (name.startsWith(c)) {
      s = 1;
    } else if (c.contains(name)) {
      s = 2;
    } else if (name.contains(c)) {
      s = 3;
    }
    if (s != null && (best == null || s < best)) best = s;
  }
  return best;
}

String? _resolveCountry(String? country) {
  if (country == null) return null;
  final normalized = _normalize(country);
  if (normalized.length == 2) return normalized.toUpperCase();
  return kCountryAliases[normalized]?.toUpperCase() ?? normalized.toUpperCase();
}

int _placeRank(String? level) => switch (level) {
      'PPLC' => 0,
      'PPLA' => 1,
      'PPLA2' => 2,
      'PPLA3' => 3,
      'PPLA4' => 4,
      'PPL' => 5,
      _ => 6,
    };

Map<String, Object?> _cityJson(City c) => <String, Object?>{
      'name': c.name,
      'nameAr': c.nameAr,
      'country': c.country,
      'state': c.state,
      'lat': c.coordinates.latitude,
      'lng': c.coordinates.longitude,
      'offsetMinutes': c.utcOffset.inMinutes,
    };

const List<List<String?>> _curatedQueries = <List<String?>>[
  ['London', 'GB', null],
  ['London', null, null],
  ['London', 'England', null],
  ['london', 'united kingdom', null],
  ['Trafalgar Square, London, UK', null, null],
  ['Cairo', 'Egypt', null],
  ['Cairo', 'EG', null],
  ['cairo', null, null],
  ['Mecca', null, null],
  ['Mecca', 'SA', null],
  ['Mecca', 'ksa', null],
  ['New York', 'USA', 'New York'],
  ['New York', 'US', null],
  ['Sydney', 'Australia', 'New South Wales'],
  ['Sydney', 'AU', 'Victoria'],
  ['Paris', 'FR', null],
  ['Par', null, null],
  ['  Istanbul  ', 'Turkey', null],
  ['Istanbul', 'türkiye', null],
  ['Nowhere', null, null],
  ['', null, null],
  ['Tehran', 'IR', null],
  ['Delhi', 'India', null],
  ['Kabul', null, null],
  ['Auckland', 'NZ', null],
  ['London', 'ZZ', null],
  ['London', 'uk', null],
  ['Sao Paulo', 'BR', null],
  ['Perth', 'AU', 'Western Australia'],
  ['Manchester', 'GB', 'England'],
];

List<Map<String, Object?>> _geocoderCurated() {
  final geocoder = BundledCityGeocoder();
  final out = <Map<String, Object?>>[];
  for (final q in _curatedQueries) {
    final results = geocoder.search(q[0]!, country: q[1], state: q[2]);
    // Re-score to flag whether the best score is held by exactly one record.
    final candidates = _candidates(q[0]!);
    final countryCode = _resolveCountry(q[1]);
    final normState = q[2] == null ? null : _normalize(q[2]!);
    final scores = <int>[];
    for (final r in kCityDataset) {
      if (countryCode != null && r.country.toUpperCase() != countryCode) continue;
      if (normState != null && (r.state == null || _normalize(r.state!) != normState)) continue;
      final s = _score(_normalize(r.name), candidates);
      if (s != null) scores.add(s);
    }
    final firstUnique = scores.isNotEmpty &&
        scores.where((s) => s == scores.reduce((a, b) => a < b ? a : b)).length == 1;
    out.add(<String, Object?>{
      'query': q[0],
      'country': q[1],
      'state': q[2],
      'results': results.map(_cityJson).toList(),
      'firstUnique': firstUnique,
    });
  }
  return out;
}

const List<List<String?>> _sqliteQueries = <List<String?>>[
  ['London', 'GB'],
  ['Mecca', null],
  ['Cairo', 'Egypt'],
  ['Cairo', 'EG'],
  ['Tehran', 'IR'],
  ['Delhi', 'IN'],
  ['Paris', 'FR'],
  ['London', 'ZZ'],
  ['London', 'uk'],
  ['القاهرة', null],
  ['القاهرة', 'EG'],
  ['مكة المكرمة', 'SA'],
  ['Riyadh', 'SA'],
  ['Istanbul', 'TR'],
  ['Kuala Lumpur', 'MY'],
  ['Jakarta', 'ID'],
  ['Karachi', 'PK'],
  ['Dhaka', 'BD'],
  ['Kathmandu', 'NP'],
  ['St. John\'s', 'CA'],
  ['Nowhere Special', null],
  ['', 'GB'],
  ['Birmingham', 'GB'],
  ['Birmingham', 'US'],
  ['Springfield', 'US'],
  ['Alexandria', 'EG'],
  ['Alexandria', 'US'],
  ['Trafalgar Square, London, UK', null],
  ['Tokyo', 'JP'],
  ['Dubai', 'AE'],
];

List<Map<String, Object?>> _geocoderSqlite() {
  final geocoder = SqliteCityGeocoder.openFile(_dbPath);
  final db = sqlite3.open(_dbPath, mode: OpenMode.readOnly);
  try {
    final out = <Map<String, Object?>>[];
    for (final q in _sqliteQueries) {
      final results = geocoder.search(q[0]!, country: q[1]);
      out.add(<String, Object?>{
        'query': q[0],
        'country': q[1],
        'results': results.map(_cityJson).toList(),
        'firstUnique': _sqliteFirstUnique(db, q[0]!, q[1]),
      });
    }
    return out;
  } finally {
    db.dispose();
    geocoder.dispose();
  }
}

/// Re-runs the geocoder's query and re-scores rows to decide whether the best
/// (score, rank) pair is held by exactly one row.
bool _sqliteFirstUnique(Database db, String query, String? country) {
  final candidates = _candidates(query);
  if (candidates.isEmpty) return false;
  final args = <Object?>['%${candidates.first}%', '%${candidates.first}%'];
  var where = "city_level LIKE 'PPL%' AND (city_name_en LIKE ? OR city_name_ar LIKE ?)";
  final iso = _resolveCountry(country);
  if (iso != null) {
    final countryId = kIsoToCountryId[iso];
    if (countryId == null) return false;
    where += ' AND country_id = ?';
    args.add(countryId);
  }
  final rows = db.select(
    'SELECT city_name_en, city_name_ar, city_level FROM prayer_times_city_lookups '
    'WHERE $where LIMIT 200',
    args,
  );
  final keys = <(int, int)>[];
  for (final row in rows) {
    final en = (row['city_name_en'] as String?)?.trim() ?? '';
    final ar = (row['city_name_ar'] as String?)?.trim();
    final score = _score(_normalize(en), candidates) ??
        (ar != null ? _score(_normalize(ar), candidates) : null);
    if (score == null) continue;
    keys.add((score, _placeRank(row['city_level'] as String?)));
  }
  if (keys.isEmpty) return false;
  keys.sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
  return keys.length == 1 || keys[0] != keys[1];
}

// -----------------------------------------------------------------------------
// City directory
// -----------------------------------------------------------------------------

Map<String, Object?> _countryJson(CountryInfo c) => <String, Object?>{
      'id': c.id,
      'nameEn': c.nameEn,
      'nameAr': c.nameAr,
      'isoCode': c.isoCode,
      'calculationMethodId': c.calculationMethodId,
      'calculationMethod': c.calculationMethod?.code,
    };

Map<String, Object?> _entryJson(CityEntry e) => <String, Object?>{
      'id': e.id,
      'nameEn': e.nameEn,
      'nameAr': e.nameAr,
      'countryId': e.countryId,
      'countryNameEn': e.countryNameEn,
      'countryNameAr': e.countryNameAr,
      'isoCode': e.isoCode,
      'lat': e.coordinates.latitude,
      'lng': e.coordinates.longitude,
      'offsetMinutes': e.utcOffset.inMinutes,
      'timeZoneId': e.timeZoneId,
      'calculationMethodId': e.calculationMethodId,
      'calculationMethod': e.calculationMethod?.code,
    };

Map<String, Object?> _directory() {
  final directory = CityDirectory.openFile(_dbPath);
  final service = PrayerTimesService(directory: directory);
  try {
    final countries = directory.countries();
    final egypt = countries.firstWhere((c) => c.isoCode == 'EG');
    final us = countries.firstWhere((c) => c.isoCode == 'US');
    final gb = countries.firstWhere((c) => c.isoCode == 'GB');
    final sa = countries.firstWhere((c) => c.isoCode == 'SA');

    final countryQueries = <String>[
      'Egypt', 'مصر', 'United States', 'united', 'Saudi', 'السعودية', 'stan',
      'Land', 'zzz', '', '  Egypt  ', 'Guinea',
    ];
    final cityPages = <List<Object?>>[
      [egypt.id, null, 1, 0], [egypt.id, null, 10, 0], [egypt.id, null, 10, 10],
      [egypt.id, 'Alex', 10, 0], [egypt.id, 'الإسك', 10, 0], [us.id, null, 25, 0],
      [us.id, 'Spring', 20, 0], [gb.id, 'London', 10, 0], [sa.id, null, 15, 0],
      [sa.id, 'مكة', 10, 0], [999, null, 10, 0],
    ];
    final searches = <List<Object?>>[
      ['القاهرة', 1, 0], ['Cairo', 1, 0], ['Cairo', 10, 0], ['Paris', 10, 0],
      ['Paris', 10, 10], ['London', 20, 0], ['مكة', 10, 0], ['New Delhi', 5, 0],
      ['', 5, 0], [null, 5, 0], ['zzzz', 5, 0], ['San', 30, 0],
    ];
    final nearest = <List<double>>[
      [30.06263, 31.24967], [21.4225, 39.8262], [0, -30], [51.508515, -0.1254872],
      [35.7750, -78.6336], [48.8566, 2.3522], [-33.8688, 151.2093], [35.6892, 51.3890],
      [28.6139, 77.2090], [24.8607, 67.0011], [-6.2088, 106.8456], [3.1390, 101.6869],
      [41.0082, 28.9784], [25.2048, 55.2708], [59.3293, 18.0686], [61.2181, -149.9003],
      [78.2232, 15.6469], [-1.2921, 36.8219], [40.7128, -74.0060], [19.4326, -99.1332],
      [64.1466, -21.9426], [-54.8019, -68.3030], [0, 0], [89.9, 0], [-89.9, 0],
      [0, 179.9], [0, -179.9], [30.0444196, 31.2357116], [21.3891, 39.8579], [24.7136, 46.6753],
    ];

    return <String, Object?>{
      'countriesCount': countries.length,
      'countries': countries.map(_countryJson).toList(),
      'countryQueries': <Map<String, Object?>>[
        for (final q in countryQueries)
          <String, Object?>{
            'query': q,
            'results': directory.countries(query: q).map((c) => c.id).toList(),
          },
      ],
      'countryById': <Map<String, Object?>>[
        for (final id in <int>[1, egypt.id, us.id, 103, 252, 999])
          <String, Object?>{
            'id': id,
            'result': directory.country(id) == null ? null : _countryJson(directory.country(id)!),
          },
      ],
      'citiesInCountry': <Map<String, Object?>>[
        for (final p in cityPages)
          <String, Object?>{
            'countryId': p[0],
            'query': p[1],
            'limit': p[2],
            'offset': p[3],
            'results': directory
                .citiesInCountry(p[0] as int, query: p[1] as String?, limit: p[2] as int, offset: p[3] as int)
                .map(_entryJson)
                .toList(),
          },
      ],
      'searchCities': <Map<String, Object?>>[
        for (final s in searches)
          <String, Object?>{
            'query': s[0],
            'limit': s[1],
            'offset': s[2],
            'results': directory
                .searchCities(query: s[0] as String?, limit: s[1] as int, offset: s[2] as int)
                .map(_entryJson)
                .toList(),
          },
      ],
      'nearestCity': <Map<String, Object?>>[
        for (final p in nearest)
          <String, Object?>{
            'lat': p[0],
            'lng': p[1],
            'result': directory.nearestCity(p[0], p[1]) == null
                ? null
                : _entryJson(directory.nearestCity(p[0], p[1])!),
          },
      ],
      'timeZonesForCountry': <Map<String, Object?>>[
        for (final c in countries)
          <String, Object?>{
            'countryId': c.id,
            'zones': directory
                .timeZonesForCountry(c.id)
                .map((z) => <String, Object?>{'ianaId': z.ianaId, 'nameAr': z.nameAr})
                .toList(),
          },
      ],
      'autoParams': <Map<String, Object?>>[
        for (final p in nearest.take(12))
          <String, Object?>{
            'lat': p[0],
            'lng': p[1],
            'params': service.autoParamsForCoordinates(p[0], p[1]) == null
                ? null
                : _paramsJson(service.autoParamsForCoordinates(p[0], p[1])!),
          },
      ],
      'timingsByCoordinatesAuto': <Map<String, Object?>>[
        for (final p in nearest.take(6))
          <String, Object?>{
            'lat': p[0],
            'lng': p[1],
            'date': '2024-04-24',
            'raw': service.timingsByCoordinatesAuto(p[0], p[1], date: DateTime(2024, 4, 24)) == null
                ? null
                : _rawJson(service.timingsByCoordinatesAuto(p[0], p[1], date: DateTime(2024, 4, 24))!),
          },
      ],
    };
  } finally {
    directory.dispose();
  }
}
