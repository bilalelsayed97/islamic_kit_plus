import '../value_objects/coordinates.dart';
import '../value_objects/method_adjustments.dart';
import '../value_objects/method_params.dart';
import 'language.dart';
import 'midnight_mode.dart';

/// A prayer-time calculation method (twilight authority).
///
/// Each method carries its numeric [id] and short [code], a human-readable
/// [methodName], and its strongly-typed [params].
///
/// Angles, intervals and per-method minute corrections are each authority's
/// published values. Methods with ids 1–23 keep the numbering of the aladhan
/// API; the regional authorities aladhan does not publish are numbered from
/// 101 so the two id spaces never collide.
enum CalculationMethod {
  karachi(
    1,
    'KARACHI',
    'University of Islamic Sciences, Karachi',
    MethodParams(
      fajrAngle: 18,
      ishaAngle: 18,
      adjustments: MethodAdjustments(dhuhr: 1),
      location: Coordinates(24.8614622, 67.0099388),
    ),
  ),
  isna(
    2,
    'ISNA',
    'Islamic Society of North America (ISNA)',
    MethodParams(
      fajrAngle: 15,
      ishaAngle: 15,
      adjustments: MethodAdjustments(dhuhr: 1),
      location: Coordinates(39.70421229999999, -86.39943869999999),
    ),
  ),
  mwl(
    3,
    'MWL',
    'Muslim World League',
    MethodParams(
      fajrAngle: 18,
      ishaAngle: 17,
      adjustments: MethodAdjustments(dhuhr: 1),
      location: Coordinates(51.5194682, -0.1360365),
    ),
  ),
  makkah(
    4,
    'MAKKAH',
    'Umm Al-Qura University, Makkah',
    MethodParams(
      fajrAngle: 18.5,
      ishaMinutesAfterMaghrib: 90,
      ramadanIshaMinutesAfterMaghrib: 120,
      location: Coordinates(21.3890824, 39.8579118),
    ),
  ),
  egypt(
    5,
    'EGYPT',
    'Egyptian General Authority of Survey',
    MethodParams(
      fajrAngle: 19.5,
      ishaAngle: 17.5,
      adjustments: MethodAdjustments(dhuhr: 1),
      location: Coordinates(30.0444196, 31.2357116),
    ),
  ),
  tehran(
    7,
    'TEHRAN',
    'Institute of Geophysics, University of Tehran',
    MethodParams(
      fajrAngle: 17.7,
      ishaAngle: 14,
      maghribAngle: 4.5,
      midnightMode: MidnightMode.jafari,
      location: Coordinates(35.6891975, 51.3889736),
    ),
  ),
  gulf(
    8,
    'GULF',
    'Gulf Region',
    MethodParams(
      fajrAngle: 19.5,
      ishaMinutesAfterMaghrib: 90,
      location: Coordinates(24.1323638, 53.3199527),
    ),
  ),
  kuwait(
    9,
    'KUWAIT',
    'Kuwait',
    MethodParams(
      fajrAngle: 18,
      ishaAngle: 17.5,
      location: Coordinates(29.375859, 47.9774052),
    ),
  ),
  qatar(
    10,
    'QATAR',
    'Qatar',
    MethodParams(
      fajrAngle: 18,
      ishaMinutesAfterMaghrib: 90,
      location: Coordinates(25.2854473, 51.5310398),
    ),
  ),
  singapore(
    11,
    'SINGAPORE',
    'Majlis Ugama Islam Singapura, Singapore',
    MethodParams(
      fajrAngle: 20,
      ishaAngle: 18,
      adjustments: MethodAdjustments(dhuhr: 1),
      location: Coordinates(1.352083, 103.819836),
    ),
  ),
  france(
    12,
    'FRANCE',
    'Union Organization Islamic de France',
    MethodParams(
      fajrAngle: 12,
      ishaAngle: 12,
      location: Coordinates(48.856614, 2.3522219),
    ),
  ),
  turkey(
    13,
    'TURKEY',
    'Diyanet İşleri Başkanlığı, Turkey',
    MethodParams(
      fajrAngle: 18,
      ishaAngle: 17,
      location: Coordinates(39.9333635, 32.8597419),
    ),
  ),
  russia(
    14,
    'RUSSIA',
    'Spiritual Administration of Muslims of Russia',
    MethodParams(
      fajrAngle: 16,
      ishaAngle: 15,
      location: Coordinates(54.73479099999999, 55.9578555),
    ),
  ),
  moonsighting(
    15,
    'MOONSIGHTING',
    'Moonsighting Committee Worldwide (Moonsighting.com)',
    MethodParams(
      fajrAngle: 18,
      ishaAngle: 18,
      adjustments: MethodAdjustments(dhuhr: 5, maghrib: 3),
    ),
    usesMoonsighting: true,
  ),
  dubai(
    16,
    'DUBAI',
    'The Gulf Region — Dubai',
    MethodParams(
      fajrAngle: 18.2,
      ishaAngle: 18.2,
      adjustments: MethodAdjustments(sunrise: -3, dhuhr: 3, asr: 3, maghrib: 3),
      location: Coordinates(25.0762677, 55.087404),
    ),
  ),
  jakim(
    17,
    'JAKIM',
    'Jabatan Kemajuan Islam Malaysia (JAKIM)',
    MethodParams(
      fajrAngle: 20,
      ishaAngle: 18,
      location: Coordinates(3.139003, 101.686855),
    ),
  ),
  tunisia(
    18,
    'TUNISIA',
    'Tunisia',
    MethodParams(
      fajrAngle: 18,
      ishaAngle: 18,
      location: Coordinates(36.8064948, 10.1815316),
    ),
  ),
  algeria(
    19,
    'ALGERIA',
    'Algeria',
    MethodParams(
      fajrAngle: 18,
      ishaAngle: 17,
      location: Coordinates(36.753768, 3.0587561),
    ),
  ),
  kemenag(
    20,
    'KEMENAG',
    'Kementerian Agama Republik Indonesia',
    MethodParams(
      fajrAngle: 20,
      ishaAngle: 18,
      location: Coordinates(-6.2087634, 106.845599),
    ),
  ),
  morocco(
    21,
    'MOROCCO',
    'Morocco',
    MethodParams(
      fajrAngle: 18,
      ishaAngle: 17,
      location: Coordinates(33.9715904, -6.8498129),
    ),
  ),
  portugal(
    22,
    'PORTUGAL',
    'Comunidade Islamica de Lisboa',
    MethodParams(
      fajrAngle: 18,
      ishaMinutesAfterMaghrib: 77,
      maghribMinutesAfterSunset: 3,
      location: Coordinates(38.7222524, -9.1393366),
    ),
  ),
  jordan(
    23,
    'JORDAN',
    'Ministry of Awqaf, Islamic Affairs and Holy Places, Jordan',
    MethodParams(
      fajrAngle: 18.5,
      ishaMinutesAfterMaghrib: 90,
      location: Coordinates(31.9461222, 35.923844),
    ),
  ),

  // ---------------------------------------------------------------------------
  // Regional authorities absent from the aladhan API.
  // Numbered from 101 so their ids never collide with aladhan's.
  // ---------------------------------------------------------------------------

  oman(
    101,
    'OMAN',
    'Ministry of Endowments and Religious Affairs, Oman',
    MethodParams(
      fajrAngle: 18.5,
      ishaMinutesAfterMaghrib: 90,
      location: Coordinates(23.5880, 58.3829),
    ),
  ),
  munich(
    102,
    'MUNICH',
    'Islamic Center of Munich, Germany',
    MethodParams(
      fajrAngle: 18,
      ishaAngle: 17,
      location: Coordinates(48.1351, 11.5820),
    ),
  ),
  maldives(
    103,
    'MALDIVES',
    'Ministry of Islamic Affairs, Maldives',
    MethodParams(
      fajrAngle: 18,
      ishaAngle: 17,
      location: Coordinates(4.1755, 73.5093),
    ),
  ),
  canada(
    104,
    'CANADA',
    'Canada',
    MethodParams(
      fajrAngle: 15,
      ishaAngle: 15,
      location: Coordinates(45.4215, -75.6972),
    ),
  ),
  tajikistan(
    105,
    'TAJIKISTAN',
    'Islamic Center of Tajikistan',
    MethodParams(
      fajrAngle: 18,
      ishaAngle: 17,
      location: Coordinates(38.5598, 68.7870),
    ),
  ),
  vienna(
    106,
    'VIENNA',
    'Islamic Community of Austria, Vienna',
    MethodParams(
      fajrAngle: 18,
      ishaAngle: 17,
      location: Coordinates(48.2082, 16.3738),
    ),
  ),
  belgium(
    107,
    'BELGIUM',
    'Belgium',
    MethodParams(
      fajrAngle: 18,
      ishaAngle: 17,
      location: Coordinates(50.8503, 4.3517),
    ),
  ),
  sudan(
    108,
    'SUDAN',
    'Sudan',
    MethodParams(
      fajrAngle: 19.5,
      ishaAngle: 17.5,
      location: Coordinates(15.5007, 32.5599),
    ),
  ),
  libya(
    109,
    'LIBYA',
    'Libya',
    MethodParams(
      fajrAngle: 19.5,
      ishaAngle: 17.5,
      location: Coordinates(32.8872, 13.1913),
    ),
  ),
  iraq(
    110,
    'IRAQ',
    'Iraq',
    MethodParams(
      fajrAngle: 18,
      ishaAngle: 17,
      location: Coordinates(33.3152, 44.3661),
    ),
  ),
  luxembourg(
    111,
    'LUXEMBOURG',
    'Luxembourg',
    MethodParams(
      fajrAngle: 18,
      ishaAngle: 17,
      location: Coordinates(49.6116, 6.1319),
    ),
  ),

  /// Placeholder for a user-supplied method. When selected, provide
  /// `CalculationParameters.customMethod` with your own [MethodParams].
  custom(
    99,
    'CUSTOM',
    'Custom',
    MethodParams(fajrAngle: 15, ishaAngle: 15),
  );

  const CalculationMethod(
    this.id,
    this.code,
    this.methodName,
    this.params, {
    this.usesMoonsighting = false,
  });

  /// Numeric id. Ids 1–23 and 99 match the aladhan `method` parameter; ids
  /// from 101 are package-specific (see the enum doc).
  final int id;

  /// Short code, e.g. `"MWL"`. Ids 1–23 match aladhan `/methods` keys.
  final String code;

  /// Human-readable authority name.
  final String methodName;

  /// The method's twilight parameters.
  final MethodParams params;

  /// Whether Fajr/Isha are bounded by the Moonsighting Committee's seasonal
  /// algorithm rather than resolved from the twilight angle alone.
  final bool usesMoonsighting;

  /// Whether this method is exposed by the aladhan API under the same id.
  bool get isAladhanMethod => id <= 99;

  static CalculationMethod fromId(int id) =>
      values.firstWhere((m) => m.id == id, orElse: () => mwl);

  static CalculationMethod fromCode(String code) =>
      values.firstWhere((m) => m.code == code, orElse: () => mwl);
}

/// End-user localization (title + description) for [CalculationMethod].
extension CalculationMethodL10n on CalculationMethod {
  /// Short UI label (the authority's name) for [language].
  String title(Language language) => switch (this) {
        CalculationMethod.karachi =>
          language == Language.ar ? 'كراتشي' : 'Karachi',
        CalculationMethod.isna => language == Language.ar
            ? 'الجمعية الإسلامية لأمريكا الشمالية'
            : 'ISNA',
        CalculationMethod.mwl => language == Language.ar
            ? 'رابطة العالم الإسلامي'
            : 'Muslim World League',
        CalculationMethod.makkah =>
          language == Language.ar ? 'أم القرى' : 'Umm al-Qura',
        CalculationMethod.egypt => language == Language.ar ? 'مصر' : 'Egypt',
        CalculationMethod.tehran =>
          language == Language.ar ? 'طهران' : 'Tehran',
        CalculationMethod.gulf =>
          language == Language.ar ? 'منطقة الخليج' : 'Gulf Region',
        CalculationMethod.kuwait =>
          language == Language.ar ? 'الكويت' : 'Kuwait',
        CalculationMethod.qatar => language == Language.ar ? 'قطر' : 'Qatar',
        CalculationMethod.singapore =>
          language == Language.ar ? 'سنغافورة' : 'Singapore (MUIS)',
        CalculationMethod.france =>
          language == Language.ar ? 'فرنسا' : 'France (UOIF)',
        CalculationMethod.turkey =>
          language == Language.ar ? 'تركيا (ديانت)' : 'Turkey (Diyanet)',
        CalculationMethod.russia =>
          language == Language.ar ? 'روسيا' : 'Russia',
        CalculationMethod.moonsighting => language == Language.ar
            ? 'لجنة رؤية الهلال'
            : 'Moonsighting Committee',
        CalculationMethod.dubai => language == Language.ar ? 'دبي' : 'Dubai',
        CalculationMethod.jakim =>
          language == Language.ar ? 'ماليزيا (جاكيم)' : 'Malaysia (JAKIM)',
        CalculationMethod.tunisia =>
          language == Language.ar ? 'تونس' : 'Tunisia',
        CalculationMethod.algeria =>
          language == Language.ar ? 'الجزائر' : 'Algeria',
        CalculationMethod.kemenag => language == Language.ar
            ? 'إندونيسيا (كيمناغ)'
            : 'Indonesia (Kemenag)',
        CalculationMethod.morocco =>
          language == Language.ar ? 'المغرب' : 'Morocco',
        CalculationMethod.portugal =>
          language == Language.ar ? 'البرتغال' : 'Portugal',
        CalculationMethod.jordan =>
          language == Language.ar ? 'الأردن' : 'Jordan',
        CalculationMethod.oman => language == Language.ar ? 'عُمان' : 'Oman',
        CalculationMethod.munich =>
          language == Language.ar ? 'ألمانيا (ميونخ)' : 'Germany (Munich)',
        CalculationMethod.maldives =>
          language == Language.ar ? 'المالديف' : 'Maldives',
        CalculationMethod.canada => language == Language.ar ? 'كندا' : 'Canada',
        CalculationMethod.tajikistan =>
          language == Language.ar ? 'طاجيكستان' : 'Tajikistan',
        CalculationMethod.vienna =>
          language == Language.ar ? 'النمسا (فيينا)' : 'Austria (Vienna)',
        CalculationMethod.belgium =>
          language == Language.ar ? 'بلجيكا' : 'Belgium',
        CalculationMethod.sudan =>
          language == Language.ar ? 'السودان' : 'Sudan',
        CalculationMethod.libya => language == Language.ar ? 'ليبيا' : 'Libya',
        CalculationMethod.iraq => language == Language.ar ? 'العراق' : 'Iraq',
        CalculationMethod.luxembourg =>
          language == Language.ar ? 'لوكسمبورغ' : 'Luxembourg',
        CalculationMethod.custom =>
          language == Language.ar ? 'مخصّص' : 'Custom',
      };

  /// One-sentence description (authority/region and its twilight convention)
  /// for [language].
  String description(Language language) => switch (this) {
        CalculationMethod.karachi => language == Language.ar
            ? 'جامعة العلوم الإسلامية بكراتشي — زاوية 18° لكل من الفجر والعشاء.'
            : 'University of Islamic Sciences, Karachi — 18° for both Fajr and Isha.',
        CalculationMethod.isna => language == Language.ar
            ? 'الجمعية الإسلامية لأمريكا الشمالية — زاوية 15° لكل من الفجر والعشاء.'
            : 'Islamic Society of North America — 15° for both Fajr and Isha.',
        CalculationMethod.mwl => language == Language.ar
            ? 'رابطة العالم الإسلامي — زاوية فجر 18° وعشاء 17°، وهي شائعة في أوروبا وغيرها.'
            : 'Muslim World League — 18° Fajr and 17° Isha, widely used across Europe and beyond.',
        CalculationMethod.makkah => language == Language.ar
            ? 'جامعة أم القرى بمكة — زاوية فجر 18.5° مع تحديد العشاء بعد 90 دقيقة من المغرب (120 دقيقة في رمضان).'
            : 'Umm Al-Qura University, Makkah — 18.5° Fajr with Isha fixed at 90 minutes after Maghrib (120 minutes during Ramadan).',
        CalculationMethod.egypt => language == Language.ar
            ? 'الهيئة المصرية العامة للمساحة — زاوية فجر 19.5° وعشاء 17.5°.'
            : 'Egyptian General Authority of Survey — 19.5° Fajr and 17.5° Isha.',
        CalculationMethod.tehran => language == Language.ar
            ? 'معهد الجيوفيزياء بجامعة طهران — زاوية فجر 17.7° وعشاء 14° مع زاوية مغرب 4.5°.'
            : 'Institute of Geophysics, University of Tehran — 17.7° Fajr and 14° Isha with a 4.5° Maghrib angle.',
        CalculationMethod.gulf => language == Language.ar
            ? 'منطقة الخليج — زاوية فجر 19.5° مع تحديد العشاء بعد 90 دقيقة من المغرب.'
            : 'Gulf Region — 19.5° Fajr with Isha fixed at 90 minutes after Maghrib.',
        CalculationMethod.kuwait => language == Language.ar
            ? 'الكويت — زاوية فجر 18° وعشاء 17.5°.'
            : 'Kuwait — 18° Fajr and 17.5° Isha.',
        CalculationMethod.qatar => language == Language.ar
            ? 'قطر — زاوية فجر 18° مع تحديد العشاء بعد 90 دقيقة من المغرب.'
            : 'Qatar — 18° Fajr with Isha fixed at 90 minutes after Maghrib.',
        CalculationMethod.singapore => language == Language.ar
            ? 'المجلس الإسلامي في سنغافورة — زاوية فجر 20° وعشاء 18°.'
            : 'Majlis Ugama Islam Singapura — 20° Fajr and 18° Isha.',
        CalculationMethod.france => language == Language.ar
            ? 'اتحاد المنظمات الإسلامية في فرنسا — زاوية 12° لكل من الفجر والعشاء.'
            : 'Union des Organisations Islamiques de France — 12° for both Fajr and Isha.',
        CalculationMethod.turkey => language == Language.ar
            ? 'رئاسة الشؤون الدينية التركية (ديانت) — زاوية فجر 18° وعشاء 17°.'
            : 'Diyanet İşleri Başkanlığı, Turkey — 18° Fajr and 17° Isha.',
        CalculationMethod.russia => language == Language.ar
            ? 'الإدارة الدينية لمسلمي روسيا — زاوية فجر 16° وعشاء 15°.'
            : 'Spiritual Administration of Muslims of Russia — 16° Fajr and 15° Isha.',
        CalculationMethod.moonsighting => language == Language.ar
            ? 'لجنة رؤية الهلال العالمية — زاوية 18° للفجر والعشاء مقيّدة بحساب موسمي يتغيّر مع خط العرض والفصل.'
            : 'Moonsighting Committee Worldwide — 18° Fajr and Isha bounded by a seasonal calculation that varies with latitude and time of year.',
        CalculationMethod.dubai => language == Language.ar
            ? 'دبي — زاوية 18.2° لكل من الفجر والعشاء.'
            : 'Dubai — 18.2° for both Fajr and Isha.',
        CalculationMethod.jakim => language == Language.ar
            ? 'دائرة التنمية الإسلامية الماليزية (جاكيم) — زاوية فجر 20° وعشاء 18°.'
            : 'Jabatan Kemajuan Islam Malaysia (JAKIM) — 20° Fajr and 18° Isha.',
        CalculationMethod.tunisia => language == Language.ar
            ? 'تونس — زاوية 18° لكل من الفجر والعشاء.'
            : 'Tunisia — 18° for both Fajr and Isha.',
        CalculationMethod.algeria => language == Language.ar
            ? 'الجزائر — زاوية فجر 18° وعشاء 17°.'
            : 'Algeria — 18° Fajr and 17° Isha.',
        CalculationMethod.kemenag => language == Language.ar
            ? 'وزارة الشؤون الدينية بجمهورية إندونيسيا — زاوية فجر 20° وعشاء 18°.'
            : 'Kementerian Agama Republik Indonesia — 20° Fajr and 18° Isha.',
        CalculationMethod.morocco => language == Language.ar
            ? 'المملكة المغربية — زاوية فجر 18° وعشاء 17°.'
            : 'Morocco — 18° Fajr and 17° Isha.',
        CalculationMethod.portugal => language == Language.ar
            ? 'الجالية الإسلامية في لشبونة — زاوية فجر 18° مع تحديد العشاء بعد 77 دقيقة من المغرب.'
            : 'Comunidade Islâmica de Lisboa — 18° Fajr with Isha fixed at 77 minutes after Maghrib.',
        CalculationMethod.jordan => language == Language.ar
            ? 'وزارة الأوقاف والشؤون والمقدسات الإسلامية بالأردن — زاوية فجر 18.5° مع تحديد العشاء بعد 90 دقيقة من المغرب.'
            : 'Ministry of Awqaf, Islamic Affairs and Holy Places, Jordan — 18.5° Fajr with Isha fixed at 90 minutes after Maghrib.',
        CalculationMethod.oman => language == Language.ar
            ? 'وزارة الأوقاف والشؤون الدينية بسلطنة عُمان — زاوية فجر 18.5° مع تحديد العشاء بعد 90 دقيقة من المغرب.'
            : 'Ministry of Endowments and Religious Affairs, Oman — 18.5° Fajr with Isha fixed at 90 minutes after Maghrib.',
        CalculationMethod.munich => language == Language.ar
            ? 'المركز الإسلامي في ميونخ بألمانيا — زاوية فجر 18° وعشاء 17°.'
            : 'Islamic Center of Munich, Germany — 18° Fajr and 17° Isha.',
        CalculationMethod.maldives => language == Language.ar
            ? 'وزارة الشؤون الإسلامية بجمهورية المالديف — زاوية فجر 18° وعشاء 17°.'
            : 'Ministry of Islamic Affairs, Maldives — 18° Fajr and 17° Isha.',
        CalculationMethod.canada => language == Language.ar
            ? 'كندا — زاوية 15° لكل من الفجر والعشاء.'
            : 'Canada — 15° for both Fajr and Isha.',
        CalculationMethod.tajikistan => language == Language.ar
            ? 'المركز الإسلامي في طاجيكستان — زاوية فجر 18° وعشاء 17°.'
            : 'Islamic Center of Tajikistan — 18° Fajr and 17° Isha.',
        CalculationMethod.vienna => language == Language.ar
            ? 'الهيئة الإسلامية في النمسا بفيينا — زاوية فجر 18° وعشاء 17°.'
            : 'Islamic Community of Austria, Vienna — 18° Fajr and 17° Isha.',
        CalculationMethod.belgium => language == Language.ar
            ? 'بلجيكا — زاوية فجر 18° وعشاء 17°.'
            : 'Belgium — 18° Fajr and 17° Isha.',
        CalculationMethod.sudan => language == Language.ar
            ? 'السودان — زاوية فجر 19.5° وعشاء 17.5°.'
            : 'Sudan — 19.5° Fajr and 17.5° Isha.',
        CalculationMethod.libya => language == Language.ar
            ? 'ليبيا — زاوية فجر 19.5° وعشاء 17.5°.'
            : 'Libya — 19.5° Fajr and 17.5° Isha.',
        CalculationMethod.iraq => language == Language.ar
            ? 'العراق — زاوية فجر 18° وعشاء 17°.'
            : 'Iraq — 18° Fajr and 17° Isha.',
        CalculationMethod.luxembourg => language == Language.ar
            ? 'لوكسمبورغ — زاوية فجر 18° وعشاء 17°.'
            : 'Luxembourg — 18° Fajr and 17° Isha.',
        CalculationMethod.custom => language == Language.ar
            ? 'طريقة مخصّصة يوفّرها المستخدم بمعاملات الشفق الخاصة به.'
            : 'A user-supplied method that uses your own twilight parameters.',
      };
}
