import '../../domain/enums/calendar_method.dart';
import '../../domain/ports/hijri_converter.dart';
import 'hjcosa_converter.dart';
import 'mathematical_converter.dart';
import 'table_hijri_converter.dart';

/// Creates the [HijriConverter] for a given [CalendarMethod].
class HijriConverterFactory {
  const HijriConverterFactory();

  HijriConverter create(CalendarMethod method) {
    switch (method) {
      case CalendarMethod.uaq:
        return const TableHijriConverter.ummAlQura();
      case CalendarMethod.diyanet:
        return const TableHijriConverter.diyanet();
      case CalendarMethod.hjcosa:
        return HjcosaConverter();
      case CalendarMethod.mathematical:
        return const MathematicalConverter();
    }
  }
}
