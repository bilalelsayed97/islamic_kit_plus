import '../../domain/enums/calculation_method.dart';
import '../../domain/enums/midnight_mode.dart';
import '../../domain/enums/prayer.dart';
import '../../domain/enums/shafaq.dart';
import '../../domain/enums/time_format.dart';
import '../../domain/models/calculation_meta.dart';
import '../../domain/models/date_info.dart';
import '../../domain/models/gregorian_date.dart';
import '../../domain/models/hijri_date.dart';
import '../../domain/models/prayer_result.dart';
import '../../domain/models/qibla_direction.dart';
import '../../domain/value_objects/method_params.dart';

/// Order of the `offset` block in aladhan `meta`.
const List<Prayer> _offsetOrder = <Prayer>[
  Prayer.imsak,
  Prayer.fajr,
  Prayer.sunrise,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.sunset,
  Prayer.maghrib,
  Prayer.isha,
  Prayer.midnight,
];

String _two(int n) => n < 10 ? '0$n' : '$n';

/// Emits whole doubles as ints (18.0 -> 18) and keeps fractional ones (18.5).
num _numFmt(double v) {
  final i = v.toInt();
  return v == i ? i : v;
}

Map<String, dynamic> _paramsJson(MethodParams p,
    {required bool moonsighting, required Shafaq shafaq}) {
  if (moonsighting) return <String, dynamic>{'shafaq': shafaq.code};
  final out = <String, dynamic>{'Fajr': _numFmt(p.fajrAngle)};
  if (p.ishaMinutesAfterMaghrib != null) {
    out['Isha'] = '${p.ishaMinutesAfterMaghrib} min';
  } else if (p.ishaAngle != null) {
    out['Isha'] = _numFmt(p.ishaAngle!);
  }
  if (p.maghribAngle != null) {
    out['Maghrib'] = _numFmt(p.maghribAngle!);
  } else if (p.maghribMinutesAfterSunset != null) {
    out['Maghrib'] = '${p.maghribMinutesAfterSunset} min';
  }
  if (p.midnightMode == MidnightMode.jafari) out['Midnight'] = 'JAFARI';
  return out;
}

Map<String, dynamic> _methodJson(CalculationMeta m) {
  final method = m.method;
  final json = <String, dynamic>{
    'id': method.id,
    'name': method.methodName,
    'params': _paramsJson(m.methodParams,
        moonsighting: method.usesMoonsighting, shafaq: m.shafaq),
  };
  final loc = m.methodParams.location;
  if (loc != null) {
    json['location'] = <String, dynamic>{
      'latitude': loc.latitude,
      'longitude': loc.longitude,
    };
  }
  return json;
}

Map<String, dynamic> _metaJson(CalculationMeta m) => <String, dynamic>{
      'latitude': m.coordinates.latitude,
      'longitude': m.coordinates.longitude,
      'timezone': m.timezone,
      'method': _methodJson(m),
      'latitudeAdjustmentMethod': m.method.usesMoonsighting
          ? 'NONE'
          : m.latitudeAdjustmentMethod.metaValue,
      'midnightMode': m.midnightMode.metaValue,
      'school': m.school.metaValue,
      'offset': <String, int>{
        for (final p in _offsetOrder) p.key: m.offsets[p] ?? 0,
      },
    };

Map<String, dynamic> _gregorianJson(GregorianDate g) => <String, dynamic>{
      'date': g.formatted,
      'format': 'DD-MM-YYYY',
      'day': _two(g.day),
      'weekday': <String, String>{'en': g.weekdayEn},
      'month': <String, dynamic>{'number': g.month, 'en': g.monthEn},
      'year': '${g.year}',
      'designation': <String, String>{
        'abbreviated': 'AD',
        'expanded': 'Anno Domini',
      },
      'lunarSighting': false,
    };

Map<String, dynamic> _hijriJson(HijriDate h) => <String, dynamic>{
      'date': h.formatted,
      'format': 'DD-MM-YYYY',
      'day': '${h.day}',
      'weekday': <String, String>{'en': h.weekdayEn, 'ar': h.weekdayAr},
      'month': <String, dynamic>{
        'number': h.month,
        'en': h.monthEn,
        'ar': h.monthAr,
        'days': h.monthLength,
      },
      'year': '${h.year}',
      'designation': <String, String>{
        'abbreviated': 'AH',
        'expanded': 'Anno Hegirae',
      },
      'holidays': h.holidays,
      'adjustedHolidays': const <String>[],
      'method': h.method.code,
    };

Map<String, dynamic> _dateJson(DateInfo d) => <String, dynamic>{
      'readable': d.readable,
      'timestamp': '${d.timestamp}',
      'hijri': _hijriJson(d.hijri),
      'gregorian': _gregorianJson(d.gregorian),
    };

Map<String, String> _timingsJson(
  PrayerResult r,
  TimeFormat format,
  bool calendar,
) {
  final suffix =
      calendar && format != TimeFormat.iso8601 && format != TimeFormat.float
          ? ' (${r.meta.timezone})'
          : '';
  final out = <String, String>{};
  for (final entry in r.timings.raw.entries) {
    out[entry.key.key] = '${r.timings.formatted(entry.key, format)}$suffix';
  }
  return out;
}

/// aladhan-compatible serialization for a single-day [PrayerResult].
extension AladhanSerialization on PrayerResult {
  /// The `data` object: `{timings, date, meta}`. When [calendar] is true,
  /// clock-formatted timings carry the ` (timezone)` suffix aladhan uses.
  Map<String, dynamic> toAladhanData({
    TimeFormat format = TimeFormat.h24,
    bool calendar = false,
  }) =>
      <String, dynamic>{
        'timings': _timingsJson(this, format, calendar),
        'date': _dateJson(date),
        'meta': _metaJson(meta),
      };

  /// The full envelope: `{code, status, data}`.
  Map<String, dynamic> toAladhanJson({TimeFormat format = TimeFormat.h24}) =>
      <String, dynamic>{
        'code': 200,
        'status': 'OK',
        'data': toAladhanData(format: format),
      };
}

/// aladhan-compatible `/methods` response, built from [CalculationMethod].
Map<String, dynamic> methodsAladhanJson() {
  final data = <String, dynamic>{};
  for (final m in CalculationMethod.values) {
    if (m == CalculationMethod.custom) {
      data[m.code] = <String, dynamic>{'id': m.id, 'name': m.methodName};
      continue;
    }
    final entry = <String, dynamic>{
      'id': m.id,
      'name': m.methodName,
      'params': _paramsJson(m.params,
          moonsighting: m.usesMoonsighting, shafaq: Shafaq.general),
    };
    final loc = m.params.location;
    if (loc != null) {
      entry['location'] = <String, dynamic>{
        'latitude': loc.latitude,
        'longitude': loc.longitude,
      };
    }
    data[m.code] = entry;
  }
  return <String, dynamic>{'code': 200, 'status': 'OK', 'data': data};
}

/// aladhan-compatible calendar response: `data` is an array of day objects.
Map<String, dynamic> calendarAladhanJson(
  List<PrayerResult> days, {
  TimeFormat format = TimeFormat.h24,
}) =>
    <String, dynamic>{
      'code': 200,
      'status': 'OK',
      'data': <Map<String, dynamic>>[
        for (final d in days) d.toAladhanData(format: format, calendar: true),
      ],
    };

/// aladhan-compatible annual calendar: `data` is a map keyed by month "1".."12".
Map<String, dynamic> annualCalendarAladhanJson(
  Map<int, List<PrayerResult>> months, {
  TimeFormat format = TimeFormat.h24,
}) =>
    <String, dynamic>{
      'code': 200,
      'status': 'OK',
      'data': <String, dynamic>{
        for (final e in months.entries)
          '${e.key}': <Map<String, dynamic>>[
            for (final d in e.value)
              d.toAladhanData(format: format, calendar: true),
          ],
      },
    };

/// aladhan-compatible next-prayer response: a `data` object whose `timings`
/// holds a single entry.
Map<String, dynamic> nextPrayerAladhanJson(
  PrayerResult dayResult,
  Prayer prayer, {
  TimeFormat format = TimeFormat.h24,
}) {
  final data = dayResult.toAladhanData(format: format);
  data['timings'] = <String, String>{
    prayer.key: dayResult.timings.formatted(prayer, format),
  };
  return <String, dynamic>{'code': 200, 'status': 'OK', 'data': data};
}

/// aladhan-compatible qibla response.
Map<String, dynamic> qiblaAladhanJson(QiblaDirection q) => <String, dynamic>{
      'code': 200,
      'status': 'OK',
      'data': <String, dynamic>{
        'latitude': q.from.latitude,
        'longitude': q.from.longitude,
        'direction': q.degrees,
      },
    };
