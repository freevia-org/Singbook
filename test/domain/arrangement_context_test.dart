import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement_context.dart';
import 'package:singbook/domain/models.dart';

SongCandidate _selected({
  String title = 'Harbor Lights',
  String artist = 'Mira North',
  String? album,
  Map<String, dynamic> metadata = const {},
  Map<String, dynamic> extra = const {},
  Map<String, String> recordingIds = const {},
}) => SongCandidate(
  providerId: 'genius',
  id: '101',
  title: title,
  artist: artist,
  album: album,
  metadata: metadata,
  extra: extra,
  recordingIds: recordingIds,
);

SongCandidate _chart({
  String provider = 'ultimateguitar',
  String title = 'Harbor Lights',
  String artist = 'Mira North',
  Map<String, dynamic> metadata = const {},
  Map<String, dynamic> extra = const {},
  Map<String, String> recordingIds = const {},
}) => SongCandidate(
  providerId: provider,
  id: '/tab/example/harbor-lights-chords-7',
  title: title,
  artist: artist,
  metadata: metadata,
  extra: extra,
  recordingIds: recordingIds,
);

void main() {
  test('exact title and structured composer credit admit lyric check', () {
    final selected = _selected(
      metadata: {
        'credits': [
          {'role': 'Composer', 'name': 'Ari Vale'},
          {'role': 'Featured artist', 'name': 'Ari Vale'},
        ],
      },
    );
    expect(
      contextualArrangementCandidate(selected, _chart(artist: 'Ari Vale')),
      isTrue,
    );
    expect(
      contextualArrangementCandidate(
        selected,
        _chart(title: 'Demo - Harbor Lights', artist: 'Ari Vale'),
      ),
      isFalse,
    );
  });

  test(
    'explicit soundtrack work permits exact work credit or anchored category',
    () {
      final selected = _selected(
        title: 'Paper Boats',
        album: 'Lantern Bay (Original Motion Picture Soundtrack)',
      );
      expect(
        contextualArrangementCandidate(
          selected,
          _chart(
            provider: 'songsterr',
            title: 'Paper Boats',
            artist: 'Lantern Bay',
          ),
        ),
        isTrue,
      );
      expect(
        contextualArrangementCandidate(
          selected,
          _chart(title: 'Lantern Bay - Paper Boats', artist: 'Misc Soundtrack'),
        ),
        isTrue,
      );
      expect(
        contextualArrangementCandidate(
          selected,
          _chart(title: 'Lantern Bay — Paper Boats', artist: 'Misc Cartoons'),
        ),
        isTrue,
      );
      expect(
        contextualArrangementCandidate(
          selected,
          _chart(
            provider: 'songsterr',
            title: 'Lantern Bay - Paper Boats',
            artist: 'Misc Cartoons',
          ),
        ),
        isFalse,
      );
      expect(
        contextualArrangementCandidate(
          selected,
          _chart(
            title: 'Lantern Bay - Paper Boats',
            artist: 'Misc Cartoons',
            metadata: const {'identityScope': 'arrangement'},
          ),
        ),
        isTrue,
      );
    },
  );

  test(
    'punctuation may normalize but edition and part qualifiers remain exact',
    () {
      final selected = _selected(
        title: "Don't Leave Yet",
        album: 'Small Harbor [Motion Picture Soundtrack]',
      );
      expect(
        contextualArrangementCandidate(
          selected,
          _chart(title: 'Small Harbor - Dont Leave Yet', artist: 'Misc Movies'),
        ),
        isTrue,
      );
      for (final chartTitle in [
        'Small Harbor - Dont Leave Yet (Live)',
        'Small Harbor - Part II - Dont Leave Yet',
        'Small Harbor - Dont Leave Yet (Intro)',
        'Small Harbor - Other Song',
      ]) {
        expect(
          contextualArrangementCandidate(
            selected,
            _chart(title: chartTitle, artist: 'Misc Movies'),
          ),
          isFalse,
          reason: chartTitle,
        );
      }
    },
  );

  test(
    'rejects cover credits, loose categories, and unanchored work prefixes',
    () {
      final selected = _selected(
        title: 'Paper Boats',
        album: 'Lantern Bay (Original Motion Picture Soundtrack)',
        metadata: {
          'credits': [
            {'role': 'Writer', 'name': 'Ari Vale'},
          ],
        },
      );
      expect(
        contextualArrangementCandidate(
          selected,
          _chart(artist: 'Peabo Bryson'),
        ),
        isFalse,
      );
      expect(
        contextualArrangementCandidate(
          selected,
          _chart(artist: 'Misc Soundtrack'),
        ),
        isFalse,
      );
      expect(
        contextualArrangementCandidate(
          selected,
          _chart(title: 'Other Film - Paper Boats', artist: 'Misc Soundtrack'),
        ),
        isFalse,
      );
      expect(
        contextualArrangementCandidate(
          selected,
          _chart(title: 'Ari Vale - Paper Boats', artist: 'Misc Soundtrack'),
        ),
        isFalse,
      );
    },
  );

  test(
    'rejects unsupported providers and unknown/non-recording identity scope',
    () {
      expect(
        contextualArrangementCandidate(
          _selected(metadata: {'identityScope': 'work'}),
          _chart(artist: 'Mira North'),
        ),
        isFalse,
      );
      expect(
        contextualArrangementCandidate(
          _selected(extra: {'identityScope': 'future-scope'}),
          _chart(artist: 'Mira North'),
        ),
        isFalse,
      );
      expect(
        contextualArrangementCandidate(
          _selected(metadata: {'identityScope': 'arrangement'}),
          _chart(artist: 'Mira North'),
        ),
        isFalse,
      );
      expect(
        contextualArrangementCandidate(
          _selected(),
          _chart(provider: 'other', artist: 'Mira North'),
        ),
        isFalse,
      );
    },
  );

  test('rejects conflicting recording IDs and explicit edition mismatch', () {
    expect(
      contextualArrangementCandidate(
        _selected(recordingIds: const {'isrc': 'USAAA0000001'}),
        _chart(
          artist: 'Mira North',
          recordingIds: const {'isrc': 'USAAA0000002'},
        ),
      ),
      isFalse,
    );
    expect(
      contextualArrangementCandidate(
        _selected(title: 'Harbor Lights (Studio Version)'),
        _chart(title: 'Harbor Lights (Live Version)', artist: 'Mira North'),
      ),
      isFalse,
    );
  });

  test('soundtrack title prefix requires explicit work suffix', () {
    final selected = _selected(title: 'Paper Boats', album: 'Lantern Bay');
    expect(
      contextualArrangementCandidate(
        selected,
        _chart(title: 'Lantern Bay - Paper Boats', artist: 'Misc Soundtrack'),
      ),
      isFalse,
    );
    expect(
      contextualArrangementCandidate(
        _selected(title: 'Paper Boats', album: 'Lantern Bay (Soundtrack)'),
        _chart(title: 'Lantern Bay - Paper Boats', artist: 'Misc Soundtrack'),
      ),
      isFalse,
    );
  });
}
