import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';

void main() {
  test('explicitly saved author-fill rejection is local reuse only', () {
    final stored = _legacyFixture();
    final selected = stored.selectedRecording!;
    final source = stored.sources.single;
    expect(selected.artist, isEmpty);
    expect(source.candidate.artist, 'Writer');
    expect(source.matchKind, MatchKind.rejected);
    expect(source.matchReason, 'identity_mismatch');
    expect(source.metadata.containsKey('resolvedPageId'), isFalse);
    expect(explicitHistoricalWorkMatches(selected, source), isFalse);
    expect(
      () => combineSources(
        selected,
        [source],
        preferredSourceId: source.id,
        allowRejectedPreferredSource: true,
      ),
      throwsA(isA<FormatException>()),
    );
    final use = HistoricalCacheUse.fromLibrarySnapshot(
      stored,
      selected,
      source,
    )!;
    final combined = combineSources(
      selected,
      [source],
      historicalCacheUses: [use],
    );
    expect(combined.body, stored.body);
    expect(combined.artist, 'Writer');
    expect(combined.selectedRecording!.toJson(), selected.toJson());
    expect(combined.sources.single.toJson(), source.toJson());
    expect(recordingCompatible(selected, source), isFalse);
  });

  for (final kind in [MatchKind.sameSong, MatchKind.sameRecording]) {
    test(
      'old ${kind.name} saved source does not require fabricated new facts',
      () {
        final json = _legacyFixture().toJson();
        final sourceJson = (json['sources'] as List).single as JsonMap;
        sourceJson['matchKind'] = kind.name;
        sourceJson['matchReason'] = kind == MatchKind.sameSong
            ? 'same_song'
            : 'same_recording';
        final stored = SongDocument.fromJson(json);
        final source = stored.sources.single;
        final selected = stored.selectedRecording!;
        final use = HistoricalCacheUse.fromLibrarySnapshot(
          stored,
          selected,
          source,
        );
        expect(use, isNotNull);
        final combined = combineSources(
          selected,
          [source],
          historicalCacheUses: [use!],
        );
        expect(combined.body, stored.body);
        expect(source.metadata.containsKey('resolvedPageId'), isFalse);
        expect(source.matchKind, kind);
        expect(recordingCompatible(selected, source), isFalse);
      },
    );
  }

  test('new equal-payload object cannot inherit a saved source capability', () {
    final stored = _legacyFixture();
    final source = stored.sources.single;
    final selected = stored.selectedRecording!;
    final use = HistoricalCacheUse.fromLibrarySnapshot(
      stored,
      selected,
      source,
    )!;
    final fresh = SourceResult.fromJson(
      jsonDecode(jsonEncode(source.toJson())) as JsonMap,
    );
    expect(use.allows(selected, fresh), isFalse);
    expect(
      () => combineSources(selected, [fresh], historicalCacheUses: [use]),
      throwsA(isA<FormatException>()),
    );
    final captured = use.capture(selected, source, fresh)!;
    expect(captured.allows(selected, fresh), isTrue);
    source.extra['changedAfterAuthorization'] = true;
    expect(use.allows(selected, source), isFalse);
    expect(use.capture(selected, source, fresh), isNull);
  });

  for (final author in ['', 'Writer']) {
    test(
      'accepted legacy cache preserves ${author.isEmpty ? 'unknown' : 'known'} author',
      () {
        final json = _legacyFixture().toJson();
        final selected = json['selectedRecording'] as JsonMap;
        final source = (json['sources'] as List).single as JsonMap;
        selected['artist'] = author;
        (source['candidate'] as JsonMap)['artist'] = author;
        source['matchKind'] = 'sameSong';
        source['matchReason'] = 'same_song';
        final stored = SongDocument.fromJson(json);
        final use = HistoricalCacheUse.fromLibrarySnapshot(
          stored,
          stored.selectedRecording!,
          stored.sources.single,
        )!;
        final result = combineSources(
          stored.selectedRecording!,
          stored.sources,
          historicalCacheUses: [use],
        );
        expect(result.artist, author);
        expect(result.body, stored.body);
      },
    );
  }

  for (final variant in [
    'unverified',
    'other rejection',
    'not explicit',
    'wrong source document',
    'wrong page',
    'wrong edition',
    'known author mismatch',
    'no rights',
    'rights page mismatch',
    'tag mismatch',
    'wrong license',
    'revision mismatch',
    'foreign URL',
    'contradictory new proof',
    'unrelated recording',
    'leading zero',
    'missing scope',
    'missing revision',
    'wrong page URL',
  ]) {
    test(
      'legacy cache policy rejects $variant without rewriting reader content',
      () {
        final json = _legacyFixture().toJson();
        final s = (json['sources'] as List).single as JsonMap;
        final c = s['candidate'] as JsonMap;
        final m = s['metadata'] as JsonMap;
        final rights = s['rights'] as JsonMap;
        final selected = json['selectedRecording'] as JsonMap;
        switch (variant) {
          case 'unverified':
            s['matchKind'] = 'unverified';
            break;
          case 'other rejection':
            s['matchReason'] = 'validation_rejected';
            break;
          case 'not explicit':
            (json['extra'] as JsonMap).remove('savedSourceId');
            break;
          case 'wrong source document':
            s['sourceDocumentId'] = 'wikisource:8';
            break;
          case 'wrong page':
            c['id'] = '8';
            break;
          case 'wrong edition':
            c['title'] = 'Example Text (Collected Edition)';
            break;
          case 'known author mismatch':
            selected['artist'] = 'Other Writer';
            break;
          case 'no rights':
            s.remove('rights');
            break;
          case 'rights page mismatch':
            rights['sourceId'] = '8';
            break;
          case 'tag mismatch':
            m['copyrightTags'] = ['Template:CC0'];
            break;
          case 'wrong license':
            rights['license'] = 'invented permission';
            break;
          case 'revision mismatch':
            m['revision'] = 124;
            break;
          case 'foreign URL':
            rights['sourceUrl'] = 'https://example.org/?curid=7';
            break;
          case 'contradictory new proof':
            m['resolvedPageId'] = '8';
            break;
          case 'unrelated recording':
            selected['providerId'] = 'catalog';
            break;
          case 'leading zero':
            selected['id'] = '07';
            break;
          case 'missing scope':
            m.remove('identityScope');
            break;
          case 'missing revision':
            m.remove('revision');
            break;
          case 'wrong page URL':
            rights['sourceUrl'] = 'https://en.wikisource.org/wiki/Other_Text';
            break;
        }
        final stored = SongDocument.fromJson(json);
        expect(
          HistoricalCacheUse.fromLibrarySnapshot(
            stored,
            stored.selectedRecording!,
            stored.sources.single,
          ),
          isNull,
        );
        expect(stored.body, contains('Invented opening words'));
        expect(
          stored.sources.single.metadata.containsKey('resolvedTitle'),
          isFalse,
        );
      },
    );
  }

  test(
    'selected Wikisource page combines and supplies its validated author',
    () {
      final selected = _selected();
      final source = _historicalSource();
      final combined = combineSources(selected, [source]);

      expect(combined.artist, 'Writer');
      expect(combined.body, 'invented short text');
      expect(combined.sources.single, same(source));
      expect(recordingCompatible(selected, source), isFalse);
    },
  );

  test(
    'coherent fresh revision 124 is accepted without pinning to old revision 123',
    () {
      final source = _historicalSource(revision: 124);
      expect(explicitHistoricalWorkMatches(_selected(), source), isTrue);
      expect(combineSources(_selected(), [source]).body, source.body);
      expect(source.metadata['revision'], 124);
      expect(source.extra['revision'], '124');
    },
  );

  for (final invalid in [
    'source missing',
    'candidate missing',
    'emitted missing',
    'null',
    'zero',
    'negative',
    'string',
    'double',
    'candidate mismatch',
    'source mismatch',
    'emitted mismatch',
    'emitted integer',
    'candidate double',
  ]) {
    test(
      'fresh proof rejects $invalid revision with valid page title and rights',
      () {
        final json = _historicalSource().toJson();
        final found = (json['candidate'] as JsonMap)['metadata'] as JsonMap;
        final metadata = json['metadata'] as JsonMap;
        switch (invalid) {
          case 'source missing':
            metadata.remove('revision');
            break;
          case 'candidate missing':
            found.remove('revision');
            break;
          case 'emitted missing':
            json.remove('revision');
            break;
          case 'null':
            metadata['revision'] = null;
            break;
          case 'zero':
            metadata['revision'] = 0;
            break;
          case 'negative':
            metadata['revision'] = -1;
            break;
          case 'string':
            metadata['revision'] = '123';
            break;
          case 'double':
            metadata['revision'] = 123.0;
            break;
          case 'candidate mismatch':
            found['revision'] = 124;
            break;
          case 'source mismatch':
            metadata['revision'] = 124;
            break;
          case 'emitted mismatch':
            json['revision'] = '124';
            break;
          case 'emitted integer':
            json['revision'] = 123;
            break;
          case 'candidate double':
            found['revision'] = 123.0;
            break;
        }
        final source = SourceResult.fromJson(json);
        expect(source.metadata['resolvedPageId'], '7');
        expect(source.candidate.title, 'Example Text');
        expect(source.extra['rights']['license'], 'Template:PD-old');
        expect(explicitHistoricalWorkMatches(_selected(), source), isFalse);
        expect(
          () => combineSources(_selected(), [source]),
          throwsA(isA<FormatException>()),
        );
      },
    );
  }

  test('unknown author stays unknown when the selected page has no author', () {
    final combined = combineSources(_selected(), [
      _historicalSource(author: ''),
    ]);
    expect(combined.artist, isEmpty);
  });

  test('scope and reason alone cannot bypass normal artist identity', () {
    final unproven = _historicalSource(proof: false);
    expect(
      () => combineSources(_selected(author: 'Writer'), [unproven]),
      throwsA(isA<FormatException>()),
    );
  });

  test('arbitrary provider cannot opt into historical text matching', () {
    final source = _historicalSource(providerId: 'other');
    expect(
      () => combineSources(_selected(), [source]),
      throwsA(isA<FormatException>()),
    );
  });

  for (final variant in [
    'wrong page',
    'wrong title',
    'different edition',
    'known author mismatch',
    'missing rights',
  ]) {
    test('rejects historical work proof with $variant', () {
      final source = switch (variant) {
        'wrong page' => _historicalSource(pageId: '8'),
        'wrong title' => _historicalSource(title: 'Other Text'),
        'different edition' => _historicalSource(
          title: 'Example Text (Collected Edition)',
        ),
        'known author mismatch' => _historicalSource(author: 'Another Writer'),
        _ => _historicalSource(rights: false),
      };
      final selected = _selected(
        author: switch (variant) {
          'known author mismatch' => 'Known Writer',
          'missing rights' => 'Writer',
          _ => '',
        },
      );
      expect(
        () => combineSources(selected, [source]),
        throwsA(isA<FormatException>()),
      );
    });
  }

  test('historical scope cannot establish recording compatibility', () {
    final selected = _selected(
      author: 'Writer',
      recordingIds: const {'isrc': 'US-AAA-00-00001'},
      album: 'Invented Album',
      duration: 180,
    );
    final source = _historicalSource(
      author: 'Writer',
      recordingIds: const {'isrc': 'US-AAA-00-00001'},
      album: 'Invented Album',
      duration: 180,
      matchKind: MatchKind.sameRecording,
    );
    expect(recordingCompatible(selected, source), isFalse);
  });

  test('ordinary blank-artist sources retain the existing identity guard', () {
    const selected = SongCandidate(
      providerId: 'catalog',
      id: '1',
      title: 'Example Text',
      artist: '',
    );
    const source = SourceResult(
      candidate: SongCandidate(
        providerId: 'other',
        id: '2',
        title: 'Example Text',
        artist: '',
      ),
      body: 'invented short text',
      matchKind: MatchKind.sameSong,
    );
    expect(
      () => combineSources(selected, [source]),
      throwsA(isA<FormatException>()),
    );
  });
}

SongDocument _legacyFixture() => SongDocument.fromJson(
  jsonDecode(
        File(
          'test/fixtures/wikisource_legacy_saved_song.json',
        ).readAsStringSync(),
      )
      as JsonMap,
);

SongCandidate _selected({
  String author = '',
  Map<String, String> recordingIds = const {},
  String? album,
  double? duration,
}) => SongCandidate(
  providerId: 'wikisource',
  id: '7',
  title: 'Example Text',
  artist: author,
  album: album,
  durationSeconds: duration,
  recordingIds: recordingIds,
  metadata: const {'identityScope': 'historicalText'},
);

SourceResult _historicalSource({
  String providerId = 'wikisource',
  String pageId = '7',
  String title = 'Example Text',
  String author = 'Writer',
  Map<String, String> recordingIds = const {},
  String? album,
  double? duration,
  bool rights = true,
  bool proof = true,
  int revision = 123,
  MatchKind matchKind = MatchKind.sameSong,
  Map<String, dynamic> metadata = const {},
  Map<String, dynamic>? candidateMetadata,
}) {
  final candidateFacts = {
    'identityScope': 'historicalText',
    'revision': revision,
    if (proof) 'resolvedPageId': pageId,
    if (proof) 'resolvedTitle': title,
    if (proof && rights) 'copyrightTags': ['Template:PD-old'],
    ...?candidateMetadata,
  };
  final sourceFacts = {
    ...candidateFacts,
    ...metadata,
    if (!rights) 'copyrightTags': const <String>[],
  };
  return SourceResult(
    candidate: SongCandidate(
      providerId: providerId,
      id: pageId,
      title: title,
      artist: author,
      album: album,
      durationSeconds: duration,
      recordingIds: recordingIds,
      metadata: candidateFacts,
    ),
    body: 'invented short text',
    metadata: sourceFacts,
    matchKind: matchKind,
    matchReason: 'explicit_historical_work',
    extra: {
      'revision': revision.toString(),
      'rights': {
        'source': 'wikisource',
        'sourceId': pageId,
        'license': rights ? 'Template:PD-old' : '',
        'permissions': {
          'status': 'per_work_and_jurisdiction',
          'tags': rights ? ['Template:PD-old'] : <String>[],
        },
      },
    },
  );
}
