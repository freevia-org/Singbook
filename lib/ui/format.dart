import 'package:intl/intl.dart';

/// Spaces a publisher's identifier for display without treating it as a
/// verified language, changing its persisted value, or changing a song title.
String formatSourceVariantLabel(String value) {
  if (value.isEmpty) return value;
  return value.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (match) => '${match[1]} ${match[2]}',
  );
}

/// Formats [seconds] as `m:ss`, rounding to the nearest second.
String formatDuration(double seconds) {
  final total = seconds.round();
  return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
}

/// A locale name that has date symbols loaded, for [locale] or else its
/// language, else English. Flutter ships date data for most but not all app
/// locales (Maltese has none), and `DateFormat` throws for an unknown locale.
String dateLocaleFor(String locale) {
  final normalized = locale.replaceAll('-', '_');
  final language = normalized.split('_').first;
  for (final candidate in [normalized, language]) {
    if (DateFormat.localeExists(candidate)) return candidate;
  }
  return 'en';
}

/// Formats [date] with the named [DateFormat] skeleton constructor (for
/// example `DateFormat.yMMMMd`) without ever throwing for a locale that lacks
/// date symbols.
String formatLocalizedDate(
  DateFormat Function([String? locale]) skeleton,
  DateTime date,
  String locale,
) {
  try {
    return skeleton(dateLocaleFor(locale)).format(date);
  } catch (_) {
    return skeleton('en').format(date);
  }
}
