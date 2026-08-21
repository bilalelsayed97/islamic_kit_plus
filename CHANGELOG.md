## 0.3.0

Prayer times are now solved from Jean Meeus' solar position with three-day
interpolation of the sun's right ascension and declination. **Times change** —
most by a minute or two, which is the point: the new engine solves each event
at the moment it occurs rather than at a fixed seed hour, and it matches the
published reference vectors to the minute.

### Added
- 11 regional authorities the previous table lacked: `oman`, `munich`,
  `maldives`, `canada`, `tajikistan`, `vienna`, `belgium`, `sudan`, `libya`,
  `iraq`, `luxembourg`. They are numbered from 101 so their ids never collide
  with aladhan's; check with the new `CalculationMethod.isAladhanMethod`.
- `MethodAdjustments` — the whole-minute corrections an authority publishes on
  top of the astronomy, exposed as `method.params.adjustments`. Several methods
  add a minute to Dhuhr; Dubai and Moonsighting shift more.
- Umm al-Qura's Ramadan Isha interval: 90 minutes lengthens to 120 for the
  month, resolved from the **date being computed** (via the Umm al-Qura table),
  so calendars generated ahead of time are correct.
- `BundledMethodMap` — translates the bundled database's `calc_method` column
  into a `CalculationMethod`. Those ids are the database's own numbering and
  collide with aladhan's above 5 (id 7 is Kuwait, not Tehran), so this map is
  the only safe way to read that column. `CountryInfo` and `CityEntry` gain a
  `calculationMethod` getter through it.
- `PrayerTimesService.autoParamsForCoordinates()` and
  `timingsByCoordinatesAuto()` — full settings from a GPS fix, using the
  bundled database's per-country preference (all 251 countries) and the
  nearest city's timezone. Pass the new `directory:` constructor argument.
- `CityEntry.calculationMethodId`, joined from the country row.

### Changed
- **Breaking — times.** Every prayer may shift. Dhuhr moves a minute later for
  MWL, ISNA, Karachi, Egypt and Singapore (their published correction, now
  modelled); Asr and the twilight times shift by up to a couple of minutes from
  the more accurate solar position.
- **Breaking — method values.** `morocco` is 18°/17° (was 19°/17°) and `jordan`
  is 18.5° with a 90-minute Isha interval (was 18°/18° with Maghrib +5), both
  following their authority's published values. `moonsighting` now uses 18°
  angles *bounded* by the seasonal calculation, rather than the seasonal value
  alone.
- **Breaking — defaults.** `highLatitudeRule` defaults to `middleOfNight` (was
  `angleBased`). An unset `midnightMode` now resolves to
  `jafari` — Midnight and the night thirds are measured sunset → next Fajr.
  Pass `MidnightMode.standard` for the old sunset → sunrise night.
- **Breaking — polar behaviour.** When the sun never crosses the horizon, every
  time is now invalid (`-----`) instead of being clamped to a plausible-looking
  value. `HighLatitudeRule.none` likewise leaves an unreachable twilight angle
  invalid rather than clamping it.
- **Breaking — `TwilightStrategy`.** The port now supplies seasonal Fajr/Isha
  offsets in seconds (`fajrSecondsBeforeSunrise`, `ishaSecondsAfterSunset`)
  instead of mutating a map of times; the engine owns how they bound the
  angle-based values. `TwilightContext` is gone.
- **Breaking — `CountryInfo.calculationMethod`** is renamed to
  `calculationMethodId` and documented as the database's own id. The old name
  now returns a `CalculationMethod` via `BundledMethodMap`.
- Times are rounded to the minute inside the engine, so a formatted result no
  longer depends on formatting-time rounding.
- `LocationDefaults` is aligned with the bundled database and covers more
  countries. It remains the fallback for when the database is not open.
- `elevation` still adjusts the horizon (sunrise earlier, sunset later).

### Note on aladhan compatibility
`toAladhanJson()` still emits the same response *shape*, but aladhan.com uses a
different solar algorithm, so individual times will now differ from theirs.

### Removed
- `sun_position.dart`, `julian_date.dart` and `degree_math.dart` — replaced by
  `astronomical.dart`, `solar_coordinates.dart` and `solar_time.dart`.

## 0.2.0

### Added
- `CityDirectory` — a browsable, localized view over the bundled database for
  location pickers: `countries()`, `citiesInCountry()`, `searchCities()`,
  `nearestCity()` (reverse geocoding) and `timeZonesForCountry()`.
- `CountryInfo`, `CityEntry` and `TimeZoneInfo` models, each carrying English
  and Arabic names together.
- Arabic timezone labels: new `prayer_times_time_zone_lookups` table covering
  all 371 IANA zones the city table references.
- `kCountryIdToIso` / `kIsoToCountryId` are now exported, so callers can map the
  database's integer `country_id` to an ISO 3166-1 alpha-2 code.
- `loadBundledCityDirectory()` and `materializeBundledCityDatabase()` in the
  Flutter entrypoint.

### Changed
- `loadBundledCityGeocoder()` now checks for an existing materialized copy
  *before* reading the asset, so launches after the first no longer pull tens of
  megabytes through `rootBundle`. The copy is version-stamped
  (`kBundledCityDatabaseVersion`) and both loaders share it.
- Both loaders accept a `directory`, so an app can keep the database somewhere
  more durable than the system temp directory.
- `prayer_times.db` is vacuumed and ships in `delete` journal mode: 39 MB → 35 MB
  with no rows removed.

## 0.1.0

- Initial release.
- Offline prayer-time calculation with 24 calculation
  methods, Asr schools, high-latitude rules, midnight modes, tuning and multiple
  output formats.
- Moonsighting Committee Worldwide Fajr/Isha twilight (general / ahmer / abyad shafaq).
- Hijri <-> Gregorian conversion with four calendar methods (Umm al-Qura, HJCoSA,
  Diyanet, Mathematical) and Islamic holidays.
- Qibla direction.
- Next prayer, monthly / annual / date-range calendars (Gregorian & Hijri).
- Offline city geocoder (bundled dataset) behind a swappable `Geocoder` port.
- English & Arabic localization for prayer, month and weekday names.
- aladhan.com-compatible JSON serialization.
