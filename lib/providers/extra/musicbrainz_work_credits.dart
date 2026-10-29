import 'dart:convert';

import '../../domain/models.dart';
import 'common.dart';

final _mbid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

String? _id(Object? value) =>
    value is String && _mbid.hasMatch(value) ? value.toLowerCase() : null;

List<String> _attributes(Object? value) => value is List
    ? value
          .whereType<String>()
          .take(30)
          .map((s) => boundedText(s, max: 100))
          .where((s) => s.isNotEmpty)
          .toList()
    : const [];

/// Keeps authorship attached to its work, separately from recording performers.
/// Only one complete, same-title performance association can donate flat credits.
JsonMap musicBrainzWorkMetadata(JsonMap recording) {
  final relations = recording['relations'];
  if (relations is! List) return {};
  final rawWorks = relations
      .whereType<Map>()
      .where((r) => r['target-type'] == 'work' || r.containsKey('work'))
      .toList();
  final works = <JsonMap>[];
  final eligibleByWork = <List<JsonMap>>[];
  for (final relation in rawWorks.take(30)) {
    final work = jsonMap(relation['work']);
    final id = _id(work['id']);
    final title = boundedText(work['title'], max: 500);
    if (relation['target-type'] != 'work' || id == null || title.isEmpty) {
      continue;
    }
    final credits = <JsonMap>[];
    final eligible = <JsonMap>[];
    final rawArtists = maps(
      work['relations'],
    ).where((r) => r['target-type'] == 'artist').toList();
    for (final raw in maps(work['relations']).take(100)) {
      if (raw['target-type'] != 'artist') continue;
      final artist = jsonMap(raw['artist']);
      final artistId = _id(artist['id']);
      final name = boundedText(artist['name'], max: 200);
      final role = boundedText(raw['type'], max: 100);
      if (artistId == null || name.isEmpty || role.isEmpty) continue;
      final credit = <String, dynamic>{
        'role': role,
        'name': name,
        'musicbrainzArtistId': artistId,
        'direction': boundedText(raw['direction'], max: 20),
        'attributes': _attributes(raw['attributes']),
        if (_id(raw['type-id']) case final String typeId)
          'relationshipTypeId': typeId,
        if (boundedText(raw['source-credit']).isNotEmpty)
          'sourceCredit': boundedText(raw['source-credit']),
        if (boundedText(raw['target-credit']).isNotEmpty)
          'targetCredit': boundedText(raw['target-credit']),
      };
      if (!credits.any((c) => jsonEncode(c) == jsonEncode(credit))) {
        credits.add(credit);
        if ({'writer', 'composer', 'lyricist'}.contains(raw['type']) &&
            raw['direction'] == 'backward' &&
            raw['attributes'] is List &&
            (raw['attributes'] as List).isEmpty &&
            artist['name'] is String &&
            (artist['name'] as String).length <= 200) {
          eligible.add(credit);
        }
      }
      if (credits.length == 30) break;
    }
    works.add({
      'musicbrainzWorkId': id,
      'title': title,
      'relationship': boundedText(relation['type'], max: 100),
      'direction': boundedText(relation['direction'], max: 20),
      'attributes': _attributes(relation['attributes']),
      if (_id(relation['type-id']) case final String typeId)
        'relationshipTypeId': typeId,
      if (work['iswcs'] is List) 'iswcs': _attributes(work['iswcs']),
      if (work['languages'] is List)
        'languages': _attributes(work['languages']),
      if (work['language'] is String)
        'language': boundedText(work['language'], max: 20),
      'credits': credits,
      'artistCreditEntriesReported': rawArtists.length,
      'artistCreditEntriesRetained': credits.length,
    });
    final completeRelations =
        work['relations'] is List &&
        (work['relations'] as List).every((r) => r is Map);
    eligibleByWork.add(
      completeRelations && rawArtists.length == credits.length ? eligible : [],
    );
  }
  if (works.isEmpty) return {};
  final result = <String, dynamic>{'musicbrainzWorks': works};
  // Multiple/invalid/partial/medley/translated associations remain scoped facts.
  // Do not flatten one constituent work's writers into the recording's credits.
  if (relations.any((r) => r is! Map) ||
      rawWorks.length != 1 ||
      works.length != 1) {
    return result;
  }
  final work = works.single;
  final original = jsonMap(rawWorks.single['work']);
  if (work['relationship'] != 'performance' ||
      work['direction'] != 'forward' ||
      (rawWorks.single['attributes'] is! List) ||
      (rawWorks.single['attributes'] as List).isNotEmpty ||
      normalized(stringValue(recording['title'])).isEmpty ||
      normalized(stringValue(recording['title'])) !=
          normalized(work['title'] as String) ||
      original['title'] is! String ||
      (original['title'] as String).length > 500) {
    return result;
  }
  final projected = <JsonMap>[];
  for (final credit in eligibleByWork.single) {
    projected.add({
      ...credit,
      'scope': 'work',
      'musicbrainzWorkId': work['musicbrainzWorkId'],
    });
  }
  if (projected.isEmpty) return result;
  result['credits'] = projected;
  for (final role in ['writer', 'composer', 'lyricist']) {
    final names = projected
        .where((c) => c['role'] == role)
        .map((c) => c['name'])
        .toSet()
        .toList();
    if (names.isNotEmpty) result['${role}s'] = names;
  }
  return result;
}
