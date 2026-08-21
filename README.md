<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="doc/header-dark.svg">
    <img alt="islamic_kit_plus" src="doc/header.svg" width="720">
  </picture>
</p>

<h1 align="center">islamic_kit_plus</h1>

<p align="center">
  Offline Islamic toolkit for Flutter — prayer times, next prayer, Hijri calendar,
  qibla, calendars, and an offline city geocoder. English &amp; Arabic. No API calls.
</p>

---

`islamic_kit_plus` computes **everything on-device**. There are **no network
requests** to aladhan.com or any other service.

Prayer times are solved from **Jean Meeus' solar position** (*Astronomical
Algorithms*, 2nd ed.), with the sun's right ascension and declination
interpolated across three days so every event is computed at the moment it
occurs rather than at a fixed seed hour. Around it sit the Moonsighting
Committee twilight, a Hijri calendar with four methods, and the qibla
calculation. JSON output mirrors the
[aladhan.com Prayer Times API](https://aladhan.com/prayer-times-api)
response **shape**.

The calculation core (prayer times, Hijri calendar, qibla, calendars) depends on
**only `dart:core` and `dart:math`**. The optional by‑city / by‑address geocoder
reads a bundled SQLite database of **265,849 places** across 251 countries and
371 timezones — 131,090 of them populated settlements, which is what city
search and reverse geocoding match against.

## Table of contents

- [Highlights](#highlights)
- [Install](#install)
- [Two import entrypoints](#two-import-entrypoints)
- [Quick start](#quick-start)
- [Zero-config & automatic per-location settings](#zero-config--automatic-per-location-settings)
- [Core concepts](#core-concepts)
- [Configuration — `CalculationParameters`](#configuration--calculationparameters)
- [Enums (with EN/AR labels)](#enums-with-enar-labels)
- [Calculation methods](#calculation-methods)
- [Reading & formatting times](#reading--formatting-times)
- [Prayer times](#prayer-times)
- [Next prayer](#next-prayer)
- [Calendars](#calendars)
- [Hijri calendar conversion](#hijri-calendar-conversion)
- [Qibla](#qibla)
- [Geocoding](#geocoding)
- [City directory (pickers & reverse geocoding)](#city-directory-pickers--reverse-geocoding)
- [Localization](#localization)
- [aladhan-compatible JSON](#aladhan-compatible-json)
- [Timezones & DST](#timezones--dst)
- [Architecture](#architecture)
- [Testing](#testing)

## Highlights

- 🕌 **Prayer times** from the Meeus solar algorithm, with 34 calculation
  methods, Asr schools, high‑latitude rules, midnight modes, per‑prayer tuning,
  and elevation.
- 🌙 **Moonsighting Committee Worldwide** Fajr/Isha (general / red / white shafaq).
- 📅 **Hijri ↔ Gregorian** conversion with four calendar methods, month lengths,
  and Islamic holidays.
- 🗓️ **Calendars** — monthly, annual, and date‑range, in both Gregorian and Hijri.
- 🧭 **Qibla** direction (great‑circle bearing to the Ka'aba).
- 🏙️ **Offline geocoding** — bundled database of 265,849 places (131k
  settlements) with English + Arabic names, behind a swappable `Geocoder` port.
- 🌐 **EN/AR localization** for prayer, month, and weekday names, plus a
  `title` / `description` on every enum for building settings UIs.
- 🔌 **aladhan‑shaped** `toAladhanJson()` — the same response structure, so an
  existing aladhan client parses it unchanged.
- 🧱 **Clean architecture**, immutable value objects, dependency‑free core.

## Install

```yaml
dependencies:
  islamic_kit_plus: ^0.3.0
```

Then `flutter pub get`.

## Two import entrypoints

| Import | Use it for |
|---|---|
| `package:islamic_kit_plus/islamic_kit_plus.dart` | The full core API. Works on any platform (VM, CLI, Flutter incl. web) with no Flutter binding required. |
| `package:islamic_kit_plus/islamic_kit_plus_flutter.dart` | Everything above **plus** `loadBundledCityGeocoder()`, which loads the bundled SQLite database via `rootBundle`. Import this in a Flutter app for by‑city / by‑address lookups. |

## Quick start

```dart
import 'package:islamic_kit_plus/islamic_kit_plus.dart';

void main() {
  final service = PrayerTimesService();

  final result = service.timings(
    DateTime(2024, 4, 24),
    const Coordinates(51.508515, -0.1254872), // London
    const CalculationParameters(
      method: CalculationMethod.isna,
      utcOffset: Duration(hours: 1), // London BST
    ),
  );

  print(result.formatted(Prayer.fajr));               // 03:57
  print(result.formatted(Prayer.asr, TimeFormat.h12)); // 4:56 pm
  print(Prayer.maghrib.title(Language.ar));            // المغرب
  print(result.date.hijri.day);                        // Hijri day number
}
```

## Zero-config & automatic per-location settings

You don't have to set every enum. There are four levels of "automatic":

**1. Sensible global defaults.** Every field of `CalculationParameters` has a
default (`method: mwl`, `school: standard`, `highLatitudeRule: middleOfNight`,
`calendarMethod: hjcosa`, `shafaq: general`, `imsakMinutes: 10`, …), so you can
call `timings` with **no params** — you only supply the UTC offset:

```dart
service.timings(
  DateTime(2024, 4, 24),
  const Coordinates(21.42, 39.83),
  const CalculationParameters(utcOffset: Duration(hours: 3)), // that's it
);
```

**2. Fully automatic by city.** `timingsByCityAuto` needs **no presets at all** —
it picks the calculation method and Asr school from the city's country (the
offline equivalent of aladhan choosing "the closest authority based on location")
and takes the UTC offset from the bundled city database:

```dart
import 'package:islamic_kit_plus/islamic_kit_plus_flutter.dart';

final service = PrayerTimesService(geocoder: await loadBundledCityGeocoder());

// No method, school, or offset needed — all inferred from "Cairo, EG":
final result = service.timingsByCityAuto('Cairo', country: 'EG', date: DateTime.now());
```

**3. Recommended params you can reuse (e.g. with coordinates).** Get the
recommended method + school for a country and pass it anywhere (timings,
calendars, next prayer), overriding anything you like:

```dart
final params = service.recommendedParams('PK', utcOffset: const Duration(hours: 5));
// -> Karachi method + Hanafi school
service.monthlyCalendar(2024, 4, coords, params);

// Or resolve straight from a country code:
CalculationMethod m = LocationDefaults.methodForCountry('US'); // ISNA
AsrSchool s        = LocationDefaults.schoolForCountry('TR');  // Hanafi
```

**4. Fully automatic from a GPS fix.** With the city database open,
`autoParamsForCoordinates` takes a latitude and longitude, finds the nearest
city, and reads the calculation method from that city's country as recorded in
the database (all 251 of them) plus the UTC offset from its timezone:

```dart
import 'package:islamic_kit_plus/islamic_kit_plus_flutter.dart';

final service = PrayerTimesService(
  directory: await loadBundledCityDirectory(),
);

// Everything inferred from the coordinates:
final result = service.timingsByCoordinatesAuto(
  21.4225, 39.8262,
  date: DateTime.now(),
); // -> Umm al-Qura, UTC+3

// Or just the parameters, to reuse elsewhere:
final params = service.autoParamsForCoordinates(21.4225, 39.8262);
```

**Country → method** defaults (the fallback when the database is not open):
US/MX → ISNA, CA → Canada, SA/YE/BH/SY → Makkah, AE → Dubai, KW → Kuwait,
QA → Qatar, OM → Oman, EG/NG → Egypt, SD/SS → Sudan, IQ → Iraq, LY → Libya,
JO → Jordan, DZ → Algeria, MA/EH → Morocco, TN → Tunisia, IR → Tehran,
TR → Turkey, RU → Russia, TJ → Tajikistan, PK/IN/BD/AF → Karachi,
MV → Maldives, ID/MY/SG → Singapore, BN → JAKIM, FR/MF → France, PT → Portugal,
DE → Munich, AT → Vienna, BE → Belgium, LU → Luxembourg — everything else →
Muslim World League. Hanafi Asr is the default for PK, IN, BD, AF, TR. All of
this is overridable.

> The one thing not auto-detected is **daylight saving** — bundled city offsets
> are standard time. See [Timezones & DST](#timezones--dst).

## Core concepts

| Type | What it is |
|---|---|
| `PrayerTimesService` | The **facade** you call for every feature. Construct once and reuse. |
| `Coordinates(lat, lng)` | An immutable geographic point in decimal degrees. |
| `CalculationParameters` | Immutable bundle of all calculation settings. Use `copyWith` to tweak. |
| `PrayerResult` | The result of a timings call: `timings` + `date` (Gregorian + Hijri) + `meta`. |
| `PrayerTimings` | The set of computed times; `time(Prayer)` and `formatted(Prayer)`. |
| `PrayerTime` | A single time; `format()`, `toUtc()`, `isValid`. |
| `NextPrayer` | The next upcoming prayer, its `time`, and the date it falls on. |
| `QiblaDirection` | Bearing to the Ka'aba (degrees clockwise from true north). |

## Configuration — `CalculationParameters`

Every setting is optional and immutable. Defaults are shown.

| Field | Type | Default | Description |
|---|---|---|---|
| `method` | `CalculationMethod` | `mwl` | The twilight authority (see below). |
| `customMethod` | `MethodParams?` | `null` | Angles/intervals used when `method` is `custom`. |
| `school` | `AsrSchool` | `standard` | Asr shadow factor (Standard = 1, Hanafi = 2). |
| `asrShadowFactor` | `double?` | `null` | Overrides the school's shadow factor when set. |
| `midnightMode` | `MidnightMode?` | `null` | Overrides the midnight basis. Unset resolves to `jafari` (sunset → Fajr), the engine's basis. |
| `highLatitudeRule` | `HighLatitudeRule` | `middleOfNight` | High‑latitude Fajr/Isha bound. `none` disables it. |
| `utcOffset` | `Duration` | `Duration.zero` | **You provide this.** Offset for the target date (include DST). |
| `elevation` | `double` | `0` | Observer elevation in metres. Dips the horizon, so sunrise comes earlier and sunset later. A package extension — the reference engine assumes sea level. |
| `shafaq` | `Shafaq` | `general` | Twilight used by the Moonsighting method for Isha. |
| `tune` | `Tune` | `Tune()` | Per‑prayer offsets in minutes (aladhan `tune`). |
| `imsakMinutes` | `int` | `10` | Minutes before Fajr for Imsak. |
| `dhuhrMinutes` | `int` | `0` | Minutes added to Dhuhr. |
| `calendarMethod` | `CalendarMethod` | `hjcosa` | Hijri method for the date block. |
| `timezoneName` | `String?` | `null` | Optional label echoed in `meta.timezone`. |

```dart
const base = CalculationParameters(method: CalculationMethod.egypt);
final tuned = base.copyWith(
  school: AsrSchool.hanafi,
  utcOffset: const Duration(hours: 2),
  tune: const Tune(fajr: -2, isha: 3), // minutes; see "Per-prayer tuning"
);
```

### Per-prayer tuning (the aladhan `tune` parameter)

Shift any prayer by a number of minutes with `Tune`. Its field order matches the
aladhan contract exactly — `Imsak, Fajr, Sunrise, Dhuhr, Asr, Maghrib,
Sunset, Isha, Midnight` (Maghrib precedes Sunset) — so you can build it from, or
export it to, the aladhan `tune` CSV:

```dart
// Named fields
const tune = Tune(fajr: 3, dhuhr: 7, isha: 8);

// From/to the aladhan "tune" query string
final parsed = Tune.fromCsv('5,3,5,7,9,-1,0,8,-6');
parsed.toCsv(); // "5,3,5,7,9,-1,0,8,-6"

final params = CalculationParameters(
  method: CalculationMethod.mwl,
  utcOffset: const Duration(hours: 3),
  tune: tune,
);
```

The applied offsets are echoed in the aladhan `meta.offset` block, just like the API.

## Enums (with EN/AR labels)

Every input is a typed enum, and **every enum exposes localized UI metadata**:

```dart
String label = CalculationMethod.mwl.title(Language.ar);        // رابطة العالم الإسلامي
String help  = AsrSchool.hanafi.description(Language.en);        // explains the shadow factor
```

| Enum | Values |
|---|---|
| `Prayer` | imsak, fajr, sunrise, dhuhr, asr, sunset, maghrib, isha, midnight, firstThird, lastThird |
| `CalculationMethod` | 33 methods (see table) + custom |
| `AsrSchool` | standard, hanafi |
| `MidnightMode` | standard, jafari |
| `HighLatitudeRule` | none, middleOfNight, oneSeventh, angleBased |
| `TimeFormat` | h24, h12, h12NoSuffix, float, iso8601 |
| `Shafaq` | general, ahmer, abyad |
| `CalendarMethod` | hjcosa, uaq, diyanet, mathematical |
| `Language` | en, ar |

`Prayer` also has `key` (aladhan JSON key), `nameEn`, `nameAr`, and
`localizedName(Language)`. Convert to/from aladhan integer ids via
`CalculationMethod.fromId(3)`, `AsrSchool.fromAladhanId(0)`, etc.

## Calculation methods

Several authorities publish times a minute or two off the pure astronomical
value — most add a minute to Dhuhr so the printed time is safely past the
zenith. Those corrections are part of the method definition and are listed here
as "adjustments"; they apply before your own `tune` offsets.

| Method | Fajr | Isha | Adjustments |
|---|---|---|---|
| `mwl` — Muslim World League | 18° | 17° | Dhuhr +1 |
| `isna` — Islamic Society of North America | 15° | 15° | Dhuhr +1 |
| `egypt` — Egyptian General Authority of Survey | 19.5° | 17.5° | Dhuhr +1 |
| `makkah` — Umm al‑Qura, Makkah | 18.5° | 90 min (**120 in Ramadan**) | |
| `karachi` — University of Islamic Sciences | 18° | 18° | Dhuhr +1 |
| `tehran` — University of Tehran | 17.7° | 14° (Maghrib 4.5°) | |
| `gulf` — Gulf Region | 19.5° | 90 min | |
| `kuwait` | 18° | 17.5° | |
| `qatar` | 18° | 90 min | |
| `singapore` — MUIS | 20° | 18° | Dhuhr +1 |
| `france` — UOIF | 12° | 12° | |
| `turkey` — Diyanet | 18° | 17° | |
| `russia` | 16° | 15° | |
| `moonsighting` — Moonsighting Committee | 18° + seasonal | 18° + seasonal | Dhuhr +5, Maghrib +3 |
| `dubai` | 18.2° | 18.2° | Sunrise −3, Dhuhr +3, Asr +3, Maghrib +3 |
| `jakim` — Malaysia | 20° | 18° | |
| `tunisia` | 18° | 18° | |
| `algeria` | 18° | 17° | |
| `kemenag` — Indonesia | 20° | 18° | |
| `morocco` | 18° | 17° | |
| `portugal` | 18° | 77 min (Maghrib 3 min) | |
| `jordan` | 18.5° | 90 min | |
| `oman` | 18.5° | 90 min | |
| `munich` — Germany | 18° | 17° | |
| `maldives` | 18° | 17° | |
| `canada` | 15° | 15° | |
| `tajikistan` | 18° | 17° | |
| `vienna` — Austria | 18° | 17° | |
| `belgium` | 18° | 17° | |
| `sudan` | 19.5° | 17.5° | |
| `libya` | 19.5° | 17.5° | |
| `iraq` | 18° | 17° | |
| `luxembourg` | 18° | 17° | |
| `custom` | your `MethodParams` | | |

`id` matches the aladhan `method` parameter for the first 22 methods and
`custom` (99). The regional authorities aladhan does not publish are numbered
from 101, so the two id spaces never collide — check with `isAladhanMethod`.

### Ramadan

`makkah` is the only method whose Isha interval changes with the season: Umm
al‑Qura lengthens 90 minutes to 120 for Ramadan. The switch is resolved from
the **date being computed** (against the Umm al‑Qura table), so a calendar
generated months ahead still gets it right.

### Custom method

```dart
const params = CalculationParameters(
  method: CalculationMethod.custom,
  customMethod: MethodParams(fajrAngle: 18, ishaMinutesAfterMaghrib: 90),
  utcOffset: Duration(hours: 3),
);
```

`MethodParams` fields: `fajrAngle`, `ishaAngle` **or** `ishaMinutesAfterMaghrib`,
`maghribAngle` **or** `maghribMinutesAfterSunset`, `midnightMode`, `location`.

## Reading & formatting times

`PrayerResult` gives you three views of each time:

```dart
final result = service.timings(date, coords, params);

// 1) Formatted string
result.formatted(Prayer.fajr);                 // "03:57"  (24h default)
result.formatted(Prayer.fajr, TimeFormat.h12); // "3:57 am"
result.formatted(Prayer.fajr, TimeFormat.iso8601); // "2024-04-24T03:57:00+01:00"

// 2) The PrayerTime object
final t = result.time(Prayer.maghrib);
t.isValid;        // false only at extreme latitudes
t.format();       // "20:12"
t.toUtc();        // absolute DateTime in UTC

// 3) A whole map
result.timings.toFormattedMap();               // { Prayer.fajr: "03:57", ... }
```

`TimeFormat` options: `h24` (`03:57`), `h12` (`3:57 am`), `h12NoSuffix` (`3:57`),
`float` (raw hours, e.g. `3.95`), `iso8601`. Times that cannot be computed return
the sentinel `invalidTime` (`-----`).

## Prayer times

```dart
// By coordinates
service.timings(DateTime(2024, 4, 24), const Coordinates(21.42, 39.83), params);

// By city (requires a geocoder — see Geocoding)
service.timingsByCity('Cairo', country: 'EG', date: DateTime.now(), params: params);

// By free‑text address
service.timingsByAddress('Trafalgar Square, London, UK', date: DateTime.now());
```

## Next prayer

Returns the next obligatory prayer strictly after the given wall‑clock instant,
rolling to the next day's Fajr if you're past Isha:

```dart
final next = service.nextPrayer(DateTime(2024, 4, 24, 13, 30), coords, params);
next.prayer;        // Prayer.asr
next.time.format(); // "16:56"
next.onDate;        // 2024-04-24

service.nextPrayerByAddress('London, UK', DateTime.now());
```

## Calendars

```dart
// Gregorian
List<PrayerResult> month = service.monthlyCalendar(2024, 4, coords, params);
Map<int, List<PrayerResult>> year = service.annualCalendar(2024, coords, params);
List<PrayerResult> range = service.rangeCalendar(
  DateTime(2024, 1, 1), DateTime(2024, 3, 31), coords, params); // ≤ 11 months

// Hijri
List<PrayerResult> hMonth = service.monthlyHijriCalendar(1446, 9, coords, params); // Ramadan
Map<int, List<PrayerResult>> hYear = service.annualHijriCalendar(1446, coords, params);

// By city
service.monthlyCalendarByCity(2024, 4, 'London', country: 'GB', params: params);
service.monthlyHijriCalendarByCity(1446, 9, 'Cairo', country: 'EG', params: params);
```

## Hijri calendar conversion

```dart
const factory = HijriConverterFactory();

final hijri = factory.create(CalendarMethod.hjcosa)
    .fromGregorian(DateTime(2025, 2, 14));
hijri.day;         // 15
hijri.monthEn;     // localized month name
hijri.monthLength; // 29 or 30
hijri.holidays;    // Islamic observances on this day (may be empty)

final gregorian = factory.create(CalendarMethod.uaq)
    .toGregorian(1446, 8, 15); // 2025-02-14
```

| Method | Basis | Valid range |
|---|---|---|
| `hjcosa` (default) | Umm al‑Qura table + Saudi sighting overrides | 1356–1500 AH |
| `uaq` | Umm al‑Qura table | 1356–1500 AH |
| `diyanet` | Diyanet table | 1318–1449 AH |
| `mathematical` | Pure arithmetic; supports a day `adjustment` | unrestricted |

```dart
// Mathematical supports a +/- day adjustment on both directions
factory.create(CalendarMethod.mathematical)
    .fromGregorian(DateTime(2025, 2, 14), adjustment: 1);
```

Out‑of‑range dates on table methods throw `ArgumentError`.

## Qibla

```dart
final q = service.qibla(const Coordinates(51.5073509, -0.1277583));
q.degrees; // 118.99 — clockwise from true north
```

## Geocoding

By‑city / by‑address lookups go through the `Geocoder` **port**, so you can choose
your source or plug in your own.

### Option A — bundled SQLite database (recommended)

Ships a 265,849‑place database — 131,090 populated settlements plus their
administrative divisions — with English + Arabic names, coordinates and
standard‑time offsets. Load it once in a Flutter app:

```dart
import 'package:islamic_kit_plus/islamic_kit_plus_flutter.dart';

final geocoder = await loadBundledCityGeocoder();
final service = PrayerTimesService(geocoder: geocoder);

service.timingsByCity('London', country: 'GB', date: DateTime.now());
```

On the Dart VM / CLI (or in tests) open it from a file path instead:

```dart
final geocoder = SqliteCityGeocoder.openFile('path/to/prayer_times.db');
```

The `state` argument of `search` / `resolve` is ignored by this geocoder and
`City.state` is always `null` — the bundled database has no administrative‑region
column. `City.utcOffset` is the standard‑time offset and does not account for DST.

### Option B — curated, zero‑dependency fallback

The default geocoder (`BundledCityGeocoder`) is a small curated city set that needs
no database and works everywhere, including web:

```dart
final service = PrayerTimesService(); // uses BundledCityGeocoder
service.timingsByCity('London', country: 'GB', date: DateTime.now());
```

### Option C — your own geocoder

```dart
class MyGeocoder extends Geocoder {
  @override
  List<City> search(String query, {String? country, String? state}) => [ /* ... */ ];
}

final service = PrayerTimesService(geocoder: MyGeocoder());
```

`country` accepts an ISO‑3166 alpha‑2 code (`"GB"`) or a common name (`"United Kingdom"`).

## City directory (pickers & reverse geocoding)

`Geocoder` answers *"which city is this text?"*. `CityDirectory` answers the
questions a location-picker asks instead, reading English and Arabic names
together so either locale renders without a second lookup:

```dart
final directory = await loadBundledCityDirectory();

directory.countries(query: 'مصر');              // -> [CountryInfo(Egypt, EG)]
directory.citiesInCountry(65, limit: 50);       // most prominent first, paged
directory.searchCities(query: 'Cairo');         // matches either language
directory.nearestCity(30.06263, 31.24967);      // -> CityEntry(Cairo, EG)
directory.timeZonesForCountry(65);              // -> [Africa/Cairo + Arabic label]
```

Two behaviours are worth knowing, because the naive query gets both wrong:

- **`nearestCity` is not a plain proximity sort.** The database records
  neighbourhoods alongside the cities containing them, so the closest row to
  central Cairo is a neighbourhood, not Cairo. Distance is weighted by
  settlement prominence, letting a nearby capital or administrative seat
  outrank a marginally closer suburb.
- **`timeZonesForCountry` filters border noise.** A handful of Egyptian border
  towns carry `Asia/Jerusalem`, which would present Egypt as a four-zone
  country. A zone is offered only when it covers at least 0.5% of the country's
  populated places.

The database keys countries by an integer `country_id`; `kCountryIdToIso` and
`kIsoToCountryId` are exported for callers that persist or branch on ISO codes.


## Localization

Two languages are provided: English and Arabic (`Language.en` / `Language.ar`).

```dart
// Prayer / month / weekday names on results
result.time(Prayer.fajr).name(Language.ar);      // الفجر
result.date.hijri.monthAr;                        // Arabic Hijri month
result.date.hijri.weekdayAr;                      // Arabic weekday

// UI metadata on every enum
CalculationMethod.makkah.title(Language.en);       // "Umm al-Qura"
HighLatitudeRule.angleBased.description(Language.ar);
```

The name tables live in `Localizer` (Hijri/Gregorian months and weekdays). Prayer
names live on the `Prayer` enum. You can adjust any string there to match your app's
wording.

## aladhan-compatible JSON

Produce the exact response shape used by the aladhan Prayer Times API:

```dart
result.toAladhanJson();
// {
//   "code": 200, "status": "OK",
//   "data": {
//     "timings": { "Fajr": "03:57", "Dhuhr": "13:00", ... },
//     "date": { "readable": "...", "timestamp": "...",
//               "gregorian": { ... }, "hijri": { ...ar names, holidays... } },
//     "meta": { "latitude": .., "method": {..}, "school": "STANDARD", ... }
//   }
// }

calendarAladhanJson(month);            // data: [ ...day objects ]  (with " (tz)" suffix)
annualCalendarAladhanJson(year);       // data: { "1": [...], ..., "12": [...] }
nextPrayerAladhanJson(dayResult, Prayer.asr); // single‑entry timings
methodsAladhanJson();                  // the /methods response
qiblaAladhanJson(qibla);
```

Choose a format: `result.toAladhanJson(format: TimeFormat.iso8601)`.

## Timezones & DST

The package intentionally ships **no timezone database** — that is what keeps the
calculation core dependency‑free. You therefore pass `utcOffset` for the target
date and **include DST yourself** (e.g. London is `Duration(hours: 1)` in summer,
`Duration.zero` in winter). The bundled geocoder stores each city's *standard‑time*
offset, which the `*ByCity` / `*ByAddress` helpers apply automatically unless you
set `utcOffset` explicitly.

## Architecture

Clean, layered, and dependency‑inverted. Dependencies point inward.

```
lib/
  islamic_kit_plus.dart          # core public API (Flutter‑free)
  islamic_kit_plus_flutter.dart  # + loadBundledCityGeocoder()
  src/
    domain/         enums, value objects, models, ports
    application/    PrayerTimesService (facade), PrayerCalculator,
                    qibla, aladhan serializer
    infrastructure/ astronomy engine, moonsighting twilight,
                    Hijri converters + data, localization, geocoders
```

- **Ports** (`Geocoder`, `HijriConverter`, `TwilightStrategy`) are interfaces in
  the domain; concrete adapters live in infrastructure and are injected via the
  service constructor.
- **Strategy** for time formats, high‑latitude rules, and twilight; **Factory** for
  Hijri converters; **Facade** for the top‑level API; **Value Objects** throughout.

## Testing

```sh
flutter test
```

The suite pins outputs to reference vectors:

- **The solar core** against Meeus' worked example 25.a (right ascension and
  declination to five decimal places) and example 7.a for the Julian day.
- **Prayer times** against a published reference vector — Raleigh NC,
  2015‑07‑12, ISNA, Hanafi — matched to the minute across all six times.
- **The method table** as an explicit list, so changing any angle or correction
  has to be deliberate.
- Moonsighting Fajr/Isha, the Ramadan Isha switch, high‑latitude bounds and
  polar‑night invalidation, all four Hijri conversion methods (with sighting
  overrides and range checks), the qibla reference value, and the
  bundled‑database geocoder and method map.
