/// A localized (English + Arabic) name pair.
typedef LocalizedName = ({String en, String ar});

/// Static English/Arabic name tables for Gregorian and Hijri calendars.
///
/// Hijri month and weekday names (with diacritics) are ported verbatim from
/// islamic-network/calendar `Helpers/Calendar.php`. Weekdays are keyed by ISO
/// weekday number (Mon = 1 … Sun = 7), matching `DateTime.weekday`.
class Localizer {
  const Localizer._();

  /// Hijri months 1..12.
  static const Map<int, LocalizedName> islamicMonths = <int, LocalizedName>{
    1: (en: 'Muharram', ar: 'مُحَرَّم'),
    2: (en: 'Safar', ar: 'صَفَر'),
    3: (en: 'Rabi al-awwal', ar: 'رَبيع الأوّل'),
    4: (en: 'Rabi al-thani', ar: 'رَبيع الثاني'),
    5: (en: 'Jumadi al-awal', ar: 'جُمادى الأول'),
    6: (en: 'Jumadi al-akhir', ar: 'جُمادى الآخر'),
    7: (en: 'Rajab', ar: 'رَجَب'),
    8: (en: 'Sha\'ban', ar: 'شَعْبان'),
    9: (en: 'Ramadan', ar: 'رَمَضان'),
    10: (en: 'Shawwal', ar: 'شَوّال'),
    11: (en: 'Dhu al-Qa\'dah', ar: 'ذوالقعدة'),
    12: (en: 'Dhu al-Hijjah', ar: 'ذوالحجة'),
  };

  /// Hijri weekday names keyed by ISO weekday (Mon = 1 … Sun = 7).
  static const Map<int, LocalizedName> hijriWeekdays = <int, LocalizedName>{
    1: (en: 'Monday', ar: 'الاثنين'),
    2: (en: 'Tuesday', ar: 'الثلاثاء'),
    3: (en: "Wednesday", ar: 'الاربعاء'),
    4: (en: 'Thursday', ar: 'الخميس'),
    5: (en: "Friday", ar: 'الجمعة'),
    6: (en: 'Saturday', ar: 'السبت'),
    7: (en: 'Sunday', ar: 'الاحد'),
  };

  /// Gregorian months 1..12.
  static const Map<int, LocalizedName> gregorianMonths = <int, LocalizedName>{
    1: (en: 'January', ar: 'يناير'),
    2: (en: 'February', ar: 'فبراير'),
    3: (en: 'March', ar: 'مارس'),
    4: (en: 'April', ar: 'أبريل'),
    5: (en: 'May', ar: 'مايو'),
    6: (en: 'June', ar: 'يونيو'),
    7: (en: 'July', ar: 'يوليو'),
    8: (en: 'August', ar: 'أغسطس'),
    9: (en: 'September', ar: 'سبتمبر'),
    10: (en: 'October', ar: 'أكتوبر'),
    11: (en: 'November', ar: 'نوفمبر'),
    12: (en: 'December', ar: 'ديسمبر'),
  };

  /// Gregorian weekday names keyed by ISO weekday (Mon = 1 … Sun = 7).
  static const Map<int, LocalizedName> gregorianWeekdays = <int, LocalizedName>{
    1: (en: 'Monday', ar: 'الإثنين'),
    2: (en: 'Tuesday', ar: 'الثلاثاء'),
    3: (en: 'Wednesday', ar: 'الأربعاء'),
    4: (en: 'Thursday', ar: 'الخميس'),
    5: (en: 'Friday', ar: 'الجمعة'),
    6: (en: 'Saturday', ar: 'السبت'),
    7: (en: 'Sunday', ar: 'الأحد'),
  };

  /// Short English month abbreviations for the `readable` label ("01 Jan 2025").
  static const List<String> monthAbbrEn = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static LocalizedName hijriWeekday(int isoWeekday) =>
      hijriWeekdays[isoWeekday]!;
  static LocalizedName gregorianWeekday(int isoWeekday) =>
      gregorianWeekdays[isoWeekday]!;
}
