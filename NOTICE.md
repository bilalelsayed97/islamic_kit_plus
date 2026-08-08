# NOTICE

`prayer_times` is a pure-Dart port of several PHP libraries by the Islamic Network
and the original PrayTimes.org work. The combined work is distributed under
**GPL-3.0-or-later** (see `LICENSE`).

## Attributions

- **Prayer time algorithm** — PrayTimes.js v2.3, © 2007–2011 PrayTimes.org,
  developed by Hamid Zarrabi-Zadeh; PHP port by Meezaan-ud-Din Abdu
  Dhil-Jalali Wal-Ikram (islamic-network/prayer-times, GPL-3.0-or-later).
  Credit to PrayTimes.org (https://praytimes.org) is retained per its terms.
- **Moonsighting Fajr/Isha twilight** — islamic-network/prayer-times-moonsighting
  (GPL-3.0-or-later).
- **Hijri calendar & holidays** — islamic-network/calendar (Apache-2.0).
- **Qibla direction** — implemented from the standard great-circle bearing formula
  to the Ka'aba (21.422517, 39.826166); consistent with islamic-network/qibla
  (GPL-3.0).

Reference API shape (JSON) modeled after the public https://aladhan.com prayer
times API. This package makes **no** network calls to aladhan.com or any service;
all values are computed locally.
