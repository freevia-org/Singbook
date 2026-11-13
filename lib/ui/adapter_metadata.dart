import '../domain/acousticbrainz_analysis.dart';
import '../providers/core/diagnostics.dart';

/// Metadata comes from imported files and synced documents, so values may have
/// an unexpected type. These read them without throwing.
double? metaDouble(Object? value) {
  final number = switch (value) {
    num() => value.toDouble(),
    String() => double.tryParse(value.trim()),
    _ => null,
  };
  return number != null && number.isFinite ? number : null;
}

int? metaInt(Object? value) => switch (value) {
  int() => value,
  num() when value.isFinite => value.toInt(),
  String() => int.tryParse(value.trim()),
  _ => null,
};

String? metaString(Object? value) => switch (value) {
  String() => value,
  num() || bool() => value.toString(),
  _ => null,
};

Map<String, Object?> diagnosticMetadata(
  Map<String, Object?> values, {
  String? providerId,
}) {
  const aliases = <String, List<String>>{
    'timeSignature': ['timeSignature', 'time_signature', 'time'],
    'tuning': ['tuning', 'tuningStrings', 'tuning_strings'],
  };
  const allowed = {
    'key',
    'capo',
    'tuning',
    'tempo',
    'timeSignature',
    'year',
    'album',
    'language',
    'composer',
    'composers',
    'lyricist',
    'lyricists',
    'author',
    'writers',
    'genre',
    'credits',
    'mediaLinks',
  };
  final output = <String, Object?>{};
  final analysis = AcousticBrainzAnalysis.fromMetadata(
    providerId ?? '',
    values,
  );
  if (analysis != null) output['acousticbrainz'] = analysis.toMetadata();
  for (final key in allowed) {
    Object? value = values[key];
    if (value == null) {
      for (final alias in aliases[key] ?? const <String>[]) {
        if (values.containsKey(alias)) {
          value = values[alias];
          break;
        }
      }
    }
    if (key == 'mediaLinks' && value is List) {
      final links = <String>[];
      for (final entry in value.take(30)) {
        final rawUrl = entry is String
            ? entry
            : entry is Map
            ? metaString(entry['url'])
            : null;
        final url = safeDiagnosticUrl(rawUrl);
        if (url == null) continue;
        final rawTitle = entry is Map ? metaString(entry['title']) : null;
        final title = rawTitle?.trim().replaceAll(RegExp(r'\s+'), ' ');
        final label = title == null || title.isEmpty || title == rawUrl
            ? url
            : '${title.length > 256 ? title.substring(0, 256) : title}\n$url';
        if (!links.contains(label)) links.add(label);
      }
      if (links.isNotEmpty) output[key] = List<String>.unmodifiable(links);
    } else if (value is List) {
      final entries = value
          .map((item) => diagnosticCredit(item))
          .whereType<String>()
          .toList(growable: false);
      if (entries.isNotEmpty) output[key] = List<String>.unmodifiable(entries);
    } else if (metaString(value) case final text? when text.trim().isNotEmpty) {
      output[key] = text.trim();
    }
  }
  return Map<String, Object?>.unmodifiable(output);
}

String? diagnosticCredit(Object? value) {
  if (value is String) return value.trim().isEmpty ? null : value.trim();
  if (value is! Map) return null;
  final name = metaString(value['name'] ?? value['artist'] ?? value['value']);
  final role = metaString(value['role'] ?? value['type']);
  final parts = [
    if (name?.trim().isNotEmpty == true) name!.trim(),
    if (role?.trim().isNotEmpty == true) role!.trim(),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}
