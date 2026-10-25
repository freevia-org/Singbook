import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/search_grouping.dart';
import 'package:singbook/providers/core/catalogs.dart';
import 'package:singbook/providers/core/service.dart' as discovery;

SongCandidate _catalog(String id, {bool duet = false}) =>
    GeniusProvider.parseSong({
      'id': int.parse(id),
      'title': 'Paper Windows',
      'primary_artist': {'name': 'Mira North'},
      'primary_artists': [
        {'name': 'Mira North'},
        if (duet) {'name': 'Theo East'},
      ],
      'featured_artists': [
        {'name': 'Guest Voice'},
      ],
      'writer_artists': [
        {'name': 'Another Writer'},
      ],
      'album': {'name': 'First Record'},
      'url': 'https://genius.com/original-fixture-$id-lyrics',
    });

void main() {
  test('catalog retains all primary performers without adding other roles', () {
    final candidate = _catalog('2', duet: true);
    expect(candidate.artist, 'Mira North & Theo East');
    expect(
      candidate.metadata['credits'],
      contains(
        allOf(
          containsPair('role', 'Artist'),
          containsPair('name', 'Theo East'),
        ),
      ),
    );
    expect(_catalog('1').artist, 'Mira North');
  });

  test('solo and duet catalog entries remain separate recording rows', () {
    final solo = _catalog('1'), duet = _catalog('2', duet: true);
    final groups = groupSearchRecordings([
      solo,
      duet,
    ], preferredProviderId: 'genius');
    expect(groups, hasLength(2));
    expect(discovery.sameSong(solo, duet), isFalse);
  });

  test('legacy primary-only selection accepts its enriched same-ID credit', () {
    final resolved = _catalog('2', duet: true);
    final legacy = SongCandidate.fromJson({
      ...resolved.toJson(),
      'artist': 'Mira North',
    });
    const body =
        'Amber windows hold the morning light\nQuiet rivers carry paper boats tonight';
    final source = SourceResult(
      candidate: resolved,
      body: body,
      matchKind: MatchKind.sameRecording,
    );
    expect(discovery.sameSong(legacy, resolved), isTrue);
    expect(discovery.sameSong(resolved, legacy), isTrue);
    expect(recordingCompatible(legacy, source), isTrue);
    expect(combineSources(legacy, [source]).body, body);
    expect(
      combineSources(resolved, [
        SourceResult(
          candidate: legacy,
          body: body,
          matchKind: MatchKind.sameRecording,
        ),
      ]).body,
      body,
    );
  });

  test('credit enrichment retains existing catalog correction tolerances', () {
    final full = _catalog('2', duet: true);
    final old = SongCandidate.fromJson({
      ...full.toJson(),
      'artist': 'Mira North',
      'durationSeconds': 200,
    });
    final revised = SongCandidate.fromJson({
      ...full.toJson(),
      'album': 'First Record (Deluxe Edition)',
      'durationSeconds': 205,
    });
    expect(discovery.sameSong(old, revised), isTrue);
    expect(discovery.sameSong(revised, old), isTrue);
    // Discovery's song match tolerance is broader than exact recording timing.
    expect(
      recordingCompatible(
        old,
        SourceResult(
          candidate: revised,
          body: 'Amber windows',
          matchKind: MatchKind.sameRecording,
        ),
      ),
      isFalse,
    );
  });

  test('legacy credit transition cannot bypass recording identity guards', () {
    final resolved = _catalog('2', duet: true);
    final legacy = SongCandidate.fromJson({
      ...resolved.toJson(),
      'artist': 'Mira North',
      'durationSeconds': 200,
      'recordingIds': {'isrc': 'AAABC0000001'},
    });
    for (final changed in <Map<String, dynamic>>[
      {'id': '3'},
      {'providerId': 'another'},
      {'title': 'Paper Windows (Live)'},
      {'artist': 'Unrelated Performer'},
      {'album': 'First Record (Live)'},
      {'durationSeconds': 220},
      {
        'recordingIds': {'isrc': 'AAABC0000002'},
      },
      {
        'metadata': {...resolved.metadata, 'identityScope': 'work'},
      },
    ]) {
      final other = SongCandidate.fromJson({...resolved.toJson(), ...changed});
      expect(
        discovery.sameSong(legacy, other),
        isFalse,
        reason: changed.keys.single,
      );
      expect(
        recordingCompatible(
          legacy,
          SourceResult(
            candidate: other,
            body: 'Amber windows',
            matchKind: MatchKind.sameRecording,
          ),
        ),
        isFalse,
        reason: changed.keys.single,
      );
    }
  });
}
