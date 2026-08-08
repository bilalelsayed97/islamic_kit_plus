import 'language.dart';

/// Twilight (shafaq) definition used by the Moonsighting Committee method for
/// computing Isha.
enum Shafaq {
  /// General twilight.
  general('general'),

  /// Red twilight (shafaq al-ahmar).
  ahmer('ahmer'),

  /// White twilight (shafaq al-abyad).
  abyad('abyad');

  const Shafaq(this.code);

  /// The aladhan `shafaq` identifier.
  final String code;

  static Shafaq fromCode(String code) =>
      values.firstWhere((s) => s.code == code, orElse: () => general);
}

/// End-user localization (title + description) for [Shafaq].
extension ShafaqL10n on Shafaq {
  /// Short UI label for [language].
  String title(Language language) => switch (this) {
        Shafaq.general => language == Language.ar ? 'عام' : 'General',
        Shafaq.ahmer =>
          language == Language.ar ? 'الشفق الأحمر' : 'Red Twilight',
        Shafaq.abyad =>
          language == Language.ar ? 'الشفق الأبيض' : 'White Twilight',
      };

  /// One-sentence description for [language].
  String description(Language language) => switch (this) {
        Shafaq.general => language == Language.ar
            ? 'الشفق العام الذي يجمع بين الحُمرة والبياض، ويُستخدم لحساب العشاء.'
            : 'General twilight, combining the red and white afterglow, used to compute Isha.',
        Shafaq.ahmer => language == Language.ar
            ? 'يُحسب وقت العشاء بناءً على مغيب الشفق الأحمر.'
            : 'Isha is based on the disappearance of the red twilight (shafaq al-ahmar).',
        Shafaq.abyad => language == Language.ar
            ? 'يُحسب وقت العشاء بناءً على مغيب الشفق الأبيض.'
            : 'Isha is based on the disappearance of the white twilight (shafaq al-abyad).',
      };
}
