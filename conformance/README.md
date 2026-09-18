# Conformance fixtures

Reference outputs of `islamic_kit_plus` (the Dart implementation) for a broad
grid of inputs. The native ports — [islamic_kit_swift](https://github.com/bilalelsayed97/islamic_kit_swift)
and [islamic_kit_android](https://github.com/bilalelsayed97/islamic_kit_android) —
vendor these files into their test resources and assert equality against them.

## Regenerating

From the package root, with the host time zone forced to UTC (a few Dart code
paths go through local `DateTime` arithmetic, so the reference is only
host-independent under UTC):

```sh
TZ=UTC dart run tool/conformance/generate.dart conformance
```

`manifest.json` records the package version, Dart SDK, git SHA and the number
of cases per file. Regenerate after any change to the calculation engine, the
Hijri tables, the localization strings or the bundled database, then copy the
files into each native repo with its `tool/sync-fixtures.sh`.

## Files

| File | Contents |
|---|---|
| `timings_matrix.json` | 14 places × 8 dates × all 34 methods → raw fractional hours per prayer (`null` = invalid). |
| `timings_detail.json` | Hand-picked cases (schools, every high-latitude rule × midnight mode, shafaq, tune, elevation, custom methods, fractional offsets, polar day/night, table edges, every calendar method) with unquantised solar events, every `TimeFormat`, epoch millis, the date block, meta and the full aladhan JSON. |
| `hijri.json` | `fromGregorian` (full entries: 17-day stride across each method's range, sighting overrides ±2 days, range edges, out-of-range errors, mathematical adjustments), `toGregorian` (month starts across the range), and a compact `daily` sweep of 2010–2030. |
| `qibla.json` | Bearings for 45 coordinates including poles, antimeridian and Makkah itself. |
| `next_prayer.json` | 90 `(from, coords, params)` cases including the after-Isha rollover. |
| `calendars.json` | Monthly, annual, range and Hijri calendars plus the `ArgumentError` cases. |
| `methods.json` | `methodsAladhanJson()` as a string and as data. |
| `aladhan.json` | Calendar / annual / next-prayer / qibla / methods envelopes as encoded strings. |
| `localization.json` | Every enum's ids, codes and EN/AR strings, the `Localizer` tables, lookup fallbacks, `LocationDefaults` and `BundledMethodMap`. |
| `moonsighting.json` | Moonsighting Committee twilight seconds for a latitude × day-of-year grid. |
| `geocoder_curated.json` | Curated `BundledCityGeocoder` searches. `firstUnique` is true when the best score is held by exactly one record. |
| `geocoder_sqlite.json` | `SqliteCityGeocoder` searches against the bundled database, with the same `firstUnique` flag over `(score, rank)`. |
| `directory.json` | `CityDirectory` countries, pages, searches, nearest-city lookups, time zones for all 251 countries and automatic parameters. |

Dart's `List.sort` is not stable, so result ordering among exact ties is
unspecified; ports compare the first result only when `firstUnique` is true
and otherwise compare result sets.
