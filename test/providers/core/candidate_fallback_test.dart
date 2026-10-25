import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

// Invented lyrics only.
const _body =
    '[G]Paper lanterns drifting over quiet harbor water\n'
    '[C]Every window glowing softly as the evening falls';

class _Charts implements LyricsProvider {
  final resolved = <String>[];
  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: 'charts',
    name: 'Charts',
    capabilities: {'lyrics', 'chords'},
  );
  SongCandidate _row(String id) => SongCandidate(
    providerId: 'charts',
    id: id,
    title: 'Harbor Song',
    artist: 'The Mariners',
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [_row('broken'), _row('good')];
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    resolved.add(candidate.id);
    if (candidate.id == 'broken') {
      throw const ProviderException('invalid_response');
    }
    return SourceResult(candidate: candidate, body: _body);
  }
}

void main() {
  test('an unreadable chart leaves the next candidate to try', () async {
    final provider = _Charts();
    final found = await findMatchingSource(
      provider,
      const SongCandidate(
        providerId: 'lyrics',
        id: 'l',
        title: 'Harbor Song',
        artist: 'The Mariners',
      ),
    );
    expect(found.candidate.id, 'good');
    expect(provider.resolved, containsAll(['broken', 'good']));
  });
}
