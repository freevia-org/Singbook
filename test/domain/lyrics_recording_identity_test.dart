import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';

const _selected = SongCandidate(
  providerId: 'genius',
  id: '2955220',
  title: 'Paper Harbor',
  artist: 'The Lanterns',
  metadata: {'identityScope': 'recording'},
);

const _originalLyrics =
    'Amber windows shine across the water\n'
    'Quiet footsteps carry us back home';
const _remixLyrics =
    'Electric colors scatter through the city\n'
    'Every heartbeat rises with the rhythm\n'
    'We are dancing underneath the neon\n'
    'Amber windows shine across the water\n'
    'Quiet footsteps carry us back home\n'
    'All the midnight streets are coming alive';
const _corroboratingLyrics =
    'Amber windows shine across the water\n'
    'Quiet footsteps carry us back home\n'
    'Morning settles softly on the harbor';

SourceResult _source(
  String provider,
  String id,
  String body, {
  MatchKind match = MatchKind.sameSong,
  Map<String, String> recordingIds = const {},
}) => SourceResult(
  candidate: SongCandidate(
    providerId: provider,
    id: id,
    title: 'Paper Harbor',
    artist: 'The Lanterns',
    metadata: const {'identityScope': 'recording'},
    recordingIds: recordingIds,
  ),
  body: body,
  matchKind: match,
);

void main() {
  test(
    'resolved selected-recording lyrics outrank longer same-song remix lyrics',
    () {
      final selectedLyrics = _source(
        _selected.providerId,
        _selected.id,
        _originalLyrics,
        match: MatchKind.sameRecording,
      );
      final remix = _source('lyrics.ovh', 'remix', _remixLyrics);

      final combined = combineSources(_selected, [remix, selectedLyrics]);

      expect(combined.body, _originalLyrics);
      expect(
        combined.sources.map((source) => source.id),
        contains(selectedLyrics.id),
      );
    },
  );

  test(
    'same-song lyrics remain a fallback when selected-recording lyrics are absent',
    () {
      final alternate = _source(
        'lyrics-site',
        'alternate',
        _corroboratingLyrics,
      );

      final combined = combineSources(_selected, [alternate]);

      expect(combined.body, _corroboratingLyrics);
    },
  );

  test('explicit source choice can select another recording', () {
    final selectedLyrics = _source(
      _selected.providerId,
      _selected.id,
      _originalLyrics,
      match: MatchKind.sameRecording,
      recordingIds: const {'isrc': 'original'},
    );
    final remix = _source(
      'lyrics-site',
      'remix',
      _remixLyrics,
      recordingIds: const {'isrc': 'remix'},
    );

    final combined = combineSources(_selected, [
      selectedLyrics,
      remix,
    ], preferredSourceId: remix.id);

    expect(combined.body, _remixLyrics);
  });
}
