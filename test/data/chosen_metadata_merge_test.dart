import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/combine.dart';

void main() {
  setUpAll(sqfliteFfiInit);
  late LibraryRepository repository;

  setUp(() async {
    repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
  });

  tearDown(() => repository.close());

  SongCandidate reference({
    String id = 'song',
    String title = 'Song',
    String artist = 'Artist',
    JsonMap metadata = const {},
  }) => SongCandidate(
    providerId: 'reference',
    id: id,
    title: title,
    artist: artist,
    metadata: metadata,
  );

  SourceResult source(
    String provider, {
    String id = 'song',
    String title = 'Song',
    String artist = 'Artist',
    String body = 'Same lyrics',
    JsonMap metadata = const {},
    JsonMap candidateMetadata = const {},
    MatchKind matchKind = MatchKind.sameSong,
  }) => SourceResult(
    candidate: SongCandidate(
      providerId: provider,
      id: id,
      title: title,
      artist: artist,
      metadata: candidateMetadata,
    ),
    body: body,
    metadata: metadata,
    matchKind: matchKind,
  );

  SongDocument savedSong(
    SongCandidate selected, {
    String id = 'saved-song',
    String? body,
    JsonMap metadata = const {},
    List<SourceResult> sources = const [],
    JsonMap extra = const {},
  }) => SongDocument(
    id: id,
    title: selected.title,
    artist: selected.artist,
    body: body ?? 'Old lyrics',
    metadata: metadata,
    sources: sources,
    selectedRecording: selected,
    extra: extra,
  );

  SongDocument replacementSong(
    SongCandidate selected, {
    String body = 'New lyrics',
    JsonMap metadata = const {},
    List<SourceResult> sources = const [],
    JsonMap extra = const {},
  }) => SongDocument(
    id: 'replacement',
    title: selected.title,
    artist: selected.artist,
    body: body,
    metadata: metadata,
    sources: sources,
    selectedRecording: selected,
    extra: extra,
  );

  Future<SongDocument> replace(
    SongDocument oldSong,
    SongDocument replacement,
  ) async {
    await repository.saveSong(oldSong);
    return repository.saveChosenSong(replacement);
  }

  test('blank incoming key recovers a matching source key', () async {
    final selected = reference();
    final oldKey = source('old-provider', metadata: {'key': 'E'});
    final incoming = source('new-provider');
    final result = await replace(
      savedSong(
        selected,
        metadata: {'key': 'E'},
        sources: [oldKey],
        extra: {
          'fieldOrigins': {'key': oldKey.id},
        },
      ),
      replacementSong(selected, metadata: {'key': '   '}, sources: [incoming]),
    );

    expect(result.metadata['key'], 'E');
    expect(result.extra['fieldOrigins']['key'], oldKey.id);
    expect(result.extra['keySourceIds'], [oldKey.id]);
  });

  test('explicit key without origin clears stale provenance', () async {
    final selected = reference();
    final oldKey = source('old-provider', metadata: {'key': 'E'});
    final result = await replace(
      savedSong(
        selected,
        metadata: {'key': 'E'},
        sources: [oldKey],
        extra: {
          'fieldOrigins': {'key': oldKey.id},
          'fieldContributors': {
            'key': [oldKey.id],
          },
          'keySourceIds': [oldKey.id],
        },
      ),
      replacementSong(
        selected,
        metadata: {'key': 'C'},
        sources: [source('new-provider')],
      ),
    );

    expect(result.metadata['key'], 'C');
    expect(result.extra['fieldOrigins'], isNot(contains('key')));
    expect(result.extra['fieldContributors'], isNot(contains('key')));
    expect(result.extra, isNot(contains('keySourceIds')));
  });

  test('conflicting key donors leave replacement key unknown', () async {
    final selected = reference();
    final e = source('provider-e', metadata: {'key': 'E'});
    final g = source('provider-g', metadata: {'key': 'G'});
    final result = await replace(
      savedSong(
        selected,
        metadata: {'key': 'E'},
        sources: [e, g],
        extra: {
          'fieldOrigins': {'key': e.id},
          'keySourceIds': [e.id],
        },
      ),
      replacementSong(selected, sources: [source('new-provider')]),
    );

    expect(result.metadata.containsKey('key'), isFalse);
    expect(result.extra['fieldOrigins'], isNot(contains('key')));
    expect(result.extra, isNot(contains('keySourceIds')));
  });

  for (final (field, oldValue, newValue) in [
    ('capo', 1, 2),
    ('tuning', 'E A D G B E', 'D A D G A D'),
  ]) {
    test('key recovery abstains on a $field mismatch', () async {
      final selected = reference();
      final donor = source(
        'old-provider',
        metadata: {'key': 'E', field: oldValue},
      );
      final result = await replace(
        savedSong(
          selected,
          metadata: {'key': 'E', field: oldValue},
          sources: [donor],
          extra: {
            'fieldOrigins': {'key': donor.id},
          },
        ),
        replacementSong(
          selected,
          metadata: {field: newValue},
          sources: [source('new-provider')],
        ),
      );

      expect(result.metadata.containsKey('key'), isFalse);
      expect(result.extra['fieldOrigins'], isNot(contains('key')));
    });
  }

  test('key recovery abstains across live and studio editions', () async {
    final selected = reference(title: 'Song (Live)');
    final donor = source(
      'old-provider',
      title: 'Song (Acoustic)',
      metadata: {'key': 'E'},
    );
    final result = await replace(
      savedSong(
        selected,
        metadata: {'key': 'E'},
        sources: [donor],
        extra: {
          'fieldOrigins': {'key': donor.id},
        },
      ),
      replacementSong(
        selected,
        sources: [source('new-provider', title: selected.title)],
      ),
    );

    expect(result.metadata.containsKey('key'), isFalse);
    expect(result.extra['fieldOrigins'], isNot(contains('key')));
  });

  test('carry composition credit, not album/year/duration', () async {
    final selected = reference();
    final oldCredit = source('credit-provider');
    final result = await replace(
      savedSong(
        selected,
        metadata: {
          'composer': 'Old Composer',
          'album': 'Old Album',
          'year': 1998,
          'durationSeconds': 240,
        },
        sources: [oldCredit],
        extra: {
          'fieldOrigins': {'composer': oldCredit.id},
          'fieldContributors': {
            'composer': [oldCredit.id],
          },
        },
      ),
      replacementSong(selected, sources: [source('new-provider')]),
    );

    expect(result.metadata['composer'], 'Old Composer');
    expect(result.extra['fieldOrigins']['composer'], oldCredit.id);
    expect(result.extra['fieldContributors']['composer'], [oldCredit.id]);
    expect(result.metadata, isNot(contains('album')));
    expect(result.metadata, isNot(contains('year')));
    expect(result.metadata, isNot(contains('durationSeconds')));
  });

  test('incoming composer and provenance replace the prior credit', () async {
    final selected = reference();
    final oldCredit = source('old-credit');
    final newCredit = source(
      'new-credit',
      metadata: {'composer': 'New Composer'},
    );
    final result = await replace(
      savedSong(
        selected,
        metadata: {'composer': 'Old Composer'},
        sources: [oldCredit],
        extra: {
          'fieldOrigins': {'composer': oldCredit.id},
        },
      ),
      replacementSong(
        selected,
        metadata: {'composer': 'New Composer'},
        sources: [newCredit],
        extra: {
          'fieldOrigins': {'composer': newCredit.id},
          'fieldContributors': {
            'composer': [newCredit.id],
          },
        },
      ),
    );

    expect(result.metadata['composer'], 'New Composer');
    expect(result.extra['fieldOrigins']['composer'], newCredit.id);
    expect(result.extra['fieldContributors']['composer'], [newCredit.id]);
  });

  test('explicit key removal stays unknown after save and reload', () async {
    final selected = reference();
    final oldKey = source('old-provider', metadata: {'key': 'E'});
    final saved = await replace(
      savedSong(
        selected,
        sources: [oldKey],
        extra: {
          'fieldOrigins': {'key': 'user'},
        },
      ),
      replacementSong(selected, sources: [source('new-provider')]),
    );
    final reloaded = await repository.getSong(saved.id);

    expect(reloaded!.metadata.containsKey('key'), isFalse);
    expect(reloaded.extra['fieldOrigins']['key'], 'user');
    expect(reloaded.extra, isNot(contains('keySourceIds')));
    expect(sourcedArrangementKey(reloaded), isNull);
  });

  test(
    'credit removal markers survive when the incoming value is absent',
    () async {
      final selected = reference();
      final result = await replace(
        savedSong(
          selected,
          extra: {
            'fieldOrigins': {'composer': 'user', 'lyricist': 'user'},
          },
        ),
        replacementSong(
          selected,
          metadata: {'composer': '   '},
          extra: {
            'fieldOrigins': {'composer': 'empty-provider'},
          },
        ),
      );
      expect(result.metadata, isNot(contains('composer')));
      expect(result.metadata, isNot(contains('lyricist')));
      expect(result.extra['fieldOrigins']['composer'], 'user');
      expect(result.extra['fieldOrigins']['lyricist'], 'user');
    },
  );

  test(
    'incoming key removal survives reload and a second replacement',
    () async {
      final selected = reference();
      final donor = source('old-key', metadata: {'key': 'E'});
      await replace(
        savedSong(selected, metadata: {'key': 'E'}, sources: [donor]),
        replacementSong(
          selected,
          extra: {
            'fieldOrigins': {'key': 'user'},
            'fieldContributors': {
              'key': [donor.id],
            },
          },
        ),
      );
      var reloaded = (await repository.getSong('saved-song'))!;
      expect(reloaded.metadata, isNot(contains('key')));
      expect(reloaded.extra['fieldOrigins']['key'], 'user');
      expect(reloaded.extra['fieldContributors'], isNot(contains('key')));
      expect(sourcedArrangementKey(reloaded), isNull);
      await repository.saveChosenSong(replacementSong(selected));
      reloaded = (await repository.getSong('saved-song'))!;
      expect(reloaded.metadata, isNot(contains('key')));
      expect(reloaded.extra['fieldOrigins']['key'], 'user');
      expect(sourcedArrangementKey(reloaded), isNull);
      final supplied = await repository.saveChosenSong(
        replacementSong(
          selected,
          metadata: {'key': 'F#'},
          extra: {
            'fieldOrigins': {'key': 'new-provider'},
          },
        ),
      );
      expect(supplied.metadata['key'], 'F#');
      expect(supplied.extra['fieldOrigins']['key'], 'new-provider');
    },
  );

  for (final field in ['composer', 'lyricist', 'copyright']) {
    test(
      'incoming $field removal blocks carry and retains the decision',
      () async {
        final selected = reference();
        final donor = source('old-credit');
        final result = await replace(
          savedSong(
            selected,
            metadata: {field: 'Prior value'},
            extra: {
              'fieldOrigins': {field: donor.id},
              'fieldContributors': {
                field: [donor.id],
              },
            },
          ),
          replacementSong(
            selected,
            extra: {
              'fieldOrigins': {field: 'user'},
              'fieldContributors': {
                field: [donor.id],
              },
            },
          ),
        );
        expect(result.metadata, isNot(contains(field)));
        expect(result.extra['fieldOrigins'][field], 'user');
        expect(result.extra['fieldContributors'], isNot(contains(field)));
        final again = await repository.saveChosenSong(
          replacementSong(selected),
        );
        expect(again.metadata, isNot(contains(field)));
        expect(again.extra['fieldOrigins'][field], 'user');
        final supplied = await repository.saveChosenSong(
          replacementSong(
            selected,
            metadata: {field: 'New value'},
            extra: {
              'fieldOrigins': {field: 'new-credit'},
            },
          ),
        );
        expect(supplied.metadata[field], 'New value');
        expect(supplied.extra['fieldOrigins'][field], 'new-credit');
      },
    );
  }

  test('same-song source can supply key but wrong identity cannot', () async {
    final selected = reference();
    final sameSong = source('same-provider', metadata: {'key': 'E'});
    final wrongIdentity = source(
      'wrong-provider',
      artist: 'Different Artist',
      metadata: {'key': 'G'},
    );
    final result = await replace(
      savedSong(selected, sources: [wrongIdentity]),
      replacementSong(selected, sources: [sameSong, wrongIdentity]),
    );

    expect(result.metadata['key'], 'E');
    expect(result.extra['fieldOrigins']['key'], sameSong.id);
    expect(result.extra['keySourceIds'], [sameSong.id]);

    final otherSelected = reference(id: 'other-song', title: 'Other Song');
    final unrelatedKey = source(
      'unrelated-provider',
      title: 'Other Song',
      artist: 'Different Artist',
      metadata: {'key': 'G'},
    );
    final unrelatedResult = await replace(
      savedSong(otherSelected, id: 'saved-other-song', sources: [unrelatedKey]),
      replacementSong(otherSelected, sources: [source('new-other-provider')]),
    );
    expect(unrelatedResult.metadata.containsKey('key'), isFalse);
    expect(unrelatedResult.extra['fieldOrigins'], isNot(contains('key')));
  });
}
