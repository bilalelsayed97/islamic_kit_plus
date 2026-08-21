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
- Offline prayer-time calculation (PrayTimes.js v2.3 algorithm) with 24 calculation
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
