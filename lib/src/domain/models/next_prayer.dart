import '../enums/prayer.dart';
import 'prayer_time.dart';

/// The next upcoming prayer relative to a given instant.
class NextPrayer {
  const NextPrayer({
    required this.prayer,
    required this.time,
    required this.onDate,
  });

  final Prayer prayer;
  final PrayerTime time;

  /// The civil date the next prayer falls on (may be the following day).
  final DateTime onDate;
}
