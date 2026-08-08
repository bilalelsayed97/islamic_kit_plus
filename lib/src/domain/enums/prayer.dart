import 'language.dart';

/// The prayers and derived times the library computes.
///
/// [key] is the canonical identifier used in the aladhan-compatible JSON model
/// (e.g. `"Fajr"`). Note the constant is `dhuhr` but its key is `"Dhuhr"`.
enum Prayer {
  imsak('Imsak', 'Imsak', 'الإمساك'),
  fajr('Fajr', 'Fajr', 'الفجر'),
  sunrise('Sunrise', 'Sunrise', 'الشروق'),
  dhuhr('Dhuhr', 'Dhuhr', 'الظهر'),
  asr('Asr', 'Asr', 'العصر'),
  sunset('Sunset', 'Sunset', 'الغروب'),
  maghrib('Maghrib', 'Maghrib', 'المغرب'),
  isha('Isha', 'Isha', 'العشاء'),
  midnight('Midnight', 'Midnight', 'منتصف الليل'),
  firstThird('Firstthird', 'First Third', 'الثلث الأول'),
  lastThird('Lastthird', 'Last Third', 'الثلث الأخير');

  const Prayer(this.key, this.nameEn, this.nameAr);

  /// Canonical aladhan JSON key, e.g. `"Fajr"`.
  final String key;

  /// English display name.
  final String nameEn;

  /// Arabic display name.
  final String nameAr;

  /// Localized display name for [language].
  String localizedName(Language language) =>
      language == Language.ar ? nameAr : nameEn;

  /// Looks a prayer up by its aladhan key.
  static Prayer fromKey(String key) => values.firstWhere(
        (p) => p.key == key,
        orElse: () => throw ArgumentError('Unknown prayer key: $key'),
      );

  /// The five obligatory daily prayers, in chronological order.
  ///
  /// Used to determine the next prayer.
  static const List<Prayer> dailyObligatory = <Prayer>[
    fajr,
    dhuhr,
    asr,
    maghrib,
    isha,
  ];
}

/// End-user localization (title + description) for [Prayer].
extension PrayerL10n on Prayer {
  /// Short UI label (the prayer/time name) for [language].
  String title(Language language) => switch (this) {
        Prayer.imsak => language == Language.ar ? 'الإمساك' : 'Imsak',
        Prayer.fajr => language == Language.ar ? 'الفجر' : 'Fajr',
        Prayer.sunrise => language == Language.ar ? 'الشروق' : 'Sunrise',
        Prayer.dhuhr => language == Language.ar ? 'الظهر' : 'Dhuhr',
        Prayer.asr => language == Language.ar ? 'العصر' : 'Asr',
        Prayer.sunset => language == Language.ar ? 'الغروب' : 'Sunset',
        Prayer.maghrib => language == Language.ar ? 'المغرب' : 'Maghrib',
        Prayer.isha => language == Language.ar ? 'العشاء' : 'Isha',
        Prayer.midnight => language == Language.ar ? 'منتصف الليل' : 'Midnight',
        Prayer.firstThird =>
          language == Language.ar ? 'الثلث الأول' : 'First Third',
        Prayer.lastThird =>
          language == Language.ar ? 'الثلث الأخير' : 'Last Third',
      };

  /// One-sentence description for [language].
  String description(Language language) => switch (this) {
        Prayer.imsak => language == Language.ar
            ? 'وقت الإمساك عن الطعام قبل الفجر أثناء الصيام.'
            : 'The time to stop eating before Fajr while fasting.',
        Prayer.fajr => language == Language.ar
            ? 'صلاة الفجر التي تُؤدَّى قبل شروق الشمس.'
            : 'The dawn prayer, observed before sunrise.',
        Prayer.sunrise => language == Language.ar
            ? 'لحظة شروق الشمس التي تنتهي عندها فترة صلاة الفجر.'
            : 'The moment the sun rises, marking the end of the Fajr window.',
        Prayer.dhuhr => language == Language.ar
            ? 'صلاة الظهر التي تُؤدَّى بعد زوال الشمس عن كبد السماء.'
            : 'The noon prayer, observed just after the sun passes its zenith.',
        Prayer.asr => language == Language.ar
            ? 'صلاة العصر في فترة ما بعد الظهر.'
            : 'The afternoon prayer.',
        Prayer.sunset => language == Language.ar
            ? 'لحظة غروب الشمس التي يبدأ عندها وقت المغرب.'
            : 'The moment the sun sets, coinciding with the start of Maghrib.',
        Prayer.maghrib => language == Language.ar
            ? 'صلاة المغرب التي تُؤدَّى بعد غروب الشمس مباشرة.'
            : 'The sunset prayer, observed just after the sun has set.',
        Prayer.isha => language == Language.ar
            ? 'صلاة العشاء التي تُؤدَّى بعد غياب الشفق.'
            : 'The night prayer, observed after twilight has disappeared.',
        Prayer.midnight => language == Language.ar
            ? 'منتصف الليل الشرعي بين الغروب والفجر.'
            : 'The midpoint of the Islamic night.',
        Prayer.firstThird => language == Language.ar
            ? 'نهاية الثلث الأول من الليل.'
            : 'The end of the first third of the night.',
        Prayer.lastThird => language == Language.ar
            ? 'بداية الثلث الأخير من الليل، وهو وقت مستحب لقيام الليل.'
            : 'The start of the last third of the night, favored for night prayer.',
      };
}
