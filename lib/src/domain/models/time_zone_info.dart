/// An IANA timezone offered for a country, with its Arabic label.
class TimeZoneInfo {
  const TimeZoneInfo({
    required this.ianaId,
    required this.countryId,
    this.nameAr,
  });

  /// IANA timezone identifier, e.g. `"America/Chicago"`.
  final String ianaId;

  /// Owning country's primary key in the bundled database.
  final int countryId;

  /// Arabic zone label, e.g. `"التوقيت الرسمي المركزي"`. `null` when unknown.
  final String? nameAr;

  @override
  bool operator ==(Object other) =>
      other is TimeZoneInfo &&
      other.ianaId == ianaId &&
      other.countryId == countryId;

  @override
  int get hashCode => Object.hash(ianaId, countryId);

  @override
  String toString() => 'TimeZoneInfo($ianaId)';
}
