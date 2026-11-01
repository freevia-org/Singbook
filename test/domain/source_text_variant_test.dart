import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/edition_identity.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/source_text_variant.dart';
import 'package:singbook/domain/song_identity.dart';

SongCandidate _candidate(String variable, {JsonMap extraMetadata = const {}}) {
  final id = '2244:$variable';
  return SongCandidate(
    providerId: 'mutopia',
    id: id,
    title: 'Same work',
    artist: 'Example Composer',
    metadata: {
      'identityScope': 'arrangement',
      'artistCreditRole': 'composer',
      'composer': 'Example Composer',
      'mutopiaEditionId': '2244',
      'sourceVariantLabel': variable,
      'version': sourceTextVariantVersion(id),
      ...extraMetadata,
    },
  );
}

void main() {
  test(
    'case-sensitive publisher variables are distinct explicit text versions',
    () {
      final lower = _candidate('text');
      final upper = _candidate('Text');
      expect(sourceTextVariant(lower)?.label, 'text');
      expect(sourceTextVariant(upper)?.label, 'Text');
      expect(explicitEditionsCompatible(lower, upper), isFalse);
      expect(explicitEditionsCompatible(lower, lower), isTrue);
    },
  );
  test('a text label requires the complete source identity binding', () {
    for (final malformed in [
      {'mutopiaEditionId': '2243'},
      {'sourceVariantLabel': 'other'},
      {'identityScope': 'recording'},
      {'artistCreditRole': 'performer'},
      {'version': 'arbitrary'},
      {'composer': 'Other Composer'},
      {'pendingMatchCheck': true},
    ]) {
      expect(
        sourceTextVariant(_candidate('text', extraMetadata: malformed)),
        isNull,
      );
    }
    expect(sourceTextVariant(_candidate('text\n')), isNull);
  });
  test(
    'publisher edition identity protects homonyms and performer records',
    () {
      final first = _candidate('text');
      final stored = SongDocument(
        id: 'saved',
        title: first.title,
        artist: first.artist,
        body: 'Invented text',
        selectedRecording: first,
      );
      expect(librarySongMatchPriority(stored, _candidate('otherText')), 1);
      final otherId = '999:text';
      final other = SongCandidate(
        providerId: 'mutopia',
        id: otherId,
        title: first.title,
        artist: first.artist,
        metadata: {
          ...first.metadata,
          'mutopiaEditionId': '999',
          'version': sourceTextVariantVersion(otherId),
        },
      );
      expect(librarySongMatchPriority(stored, other), 0);
      expect(
        librarySongMatchPriority(
          stored,
          SongCandidate(
            providerId: 'lrclib',
            id: 'recording',
            title: first.title,
            artist: first.artist,
          ),
        ),
        0,
      );
    },
  );
}
