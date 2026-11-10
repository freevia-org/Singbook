import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  SongDocument largeSong(String body, {String id = 'large'}) => SongDocument(
    id: id,
    title: 'Large document',
    artist: 'Regression fixture',
    body: body,
    extra: const {'selectedSourceId': 'provider:large-song'},
  );

  test(
    'large Unicode documents survive list, get, raw, and source merge',
    () async {
      final repository = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      try {
        // 180,000 multibyte lyric lines encode to more than 2.7 MiB. Chunk
        // boundaries split UTF-8 bytes, so the repository must join bytes before
        // decoding the document.
        final body = 'Привіт 🎵\n' * 180000;
        expect(utf8.encode(body).length, greaterThan(2700000));
        final original = largeSong(body);
        await repository.saveImportedSong(original);

        final listed = await repository.listSongs();
        expect(listed, hasLength(1));
        expect(listed.single.body, body);
        expect((await repository.getSong('large'))!.body, body);

        final raw = (await repository.getSongRaw('large'))!;
        expect(utf8.decode(utf8.encode(raw.document)), raw.document);
        expect(raw.hash, sha256.convert(utf8.encode(raw.document)).toString());
        expect(raw.document, contains('Привіт 🎵'));

        // Matching source identity forces the repository to read and merge the
        // stored document inside the same transaction.
        final merged = await repository.saveImportedSong(original);
        expect(merged.body, body);
        expect((await repository.getSong('large'))!.body, body);
      } finally {
        await repository.close();
      }
    },
  );

  test(
    'replacing a large saved song preserves the full old evidence',
    () async {
      final repository = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      try {
        const candidate = SongCandidate(
          providerId: 'provider',
          id: 'large-song',
          title: 'Large document',
          artist: 'Regression fixture',
        );
        final oldEvidence = 'older provider observation ' * 250000;
        final newEvidence = 'newer provider observation ' * 250000;
        SongDocument version(String body, String evidence) => SongDocument(
          id: 'large',
          title: candidate.title,
          artist: candidate.artist,
          body: body,
          selectedRecording: candidate,
          sources: [
            SourceResult(
              candidate: candidate,
              body: body,
              extra: {
                'discoveryEvidence': {'observation': evidence},
              },
            ),
          ],
        );

        await repository.saveChosenSong(
          version('Original lyrics', oldEvidence),
        );
        await repository.saveChosenSong(
          version('Replacement lyrics', newEvidence),
        );
        final raw = (await repository.getSongRaw('large'))!;
        expect(raw.document, contains('{x_verse: 1 json-base64url'));
        final reopened = (await repository.getSong('large'))!;
        expect(reopened.extensionError, isNull);
        expect(reopened.body, 'Replacement lyrics');
        expect(
          reopened.sources.any(
            (source) =>
                source.body == 'Replacement lyrics' &&
                jsonMap(source.extra['discoveryEvidence'])['observation'] ==
                    newEvidence,
          ),
          isTrue,
        );
        final history = reopened.extra['previousSavedVersions'] as List;
        final archived = SongDocument.fromJson(jsonMap(history.single));
        expect(archived.body, 'Original lyrics');
        expect(
          jsonMap(
                archived.sources.single.extra['discoveryEvidence'],
              )['observation'] ==
              oldEvidence,
          isTrue,
        );
      } finally {
        await repository.close();
      }
    },
  );

  test('fast Save archives legacy sources even when lyrics match', () async {
    final repo = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    addTearDown(repo.close);
    const candidate = SongCandidate(
      providerId: 'catalog',
      id: 'legacy',
      title: 'Legacy chart',
      artist: 'Fixture artist',
    );
    const oldCandidate = SongCandidate(
      providerId: 'old-provider',
      id: 'archived',
      title: 'Legacy chart',
      artist: 'Fixture artist',
    );
    final oldEvidence = 'Large older source payload\n' * 90000;
    final legacy = SongDocument(
      id: 'legacy',
      title: candidate.title,
      artist: candidate.artist,
      body: '[C]A single chart',
      selectedRecording: candidate,
      sources: [SourceResult(candidate: oldCandidate, body: oldEvidence)],
    );
    await repo.saveSong(legacy);
    final prior = (await repo.getPlayableSong(legacy.id))!;
    final priorHash = (await repo.getSongEditHash(legacy.id))!;
    expect(prior.sources.single.body, oldEvidence);
    await repo.beginDiscoverySession(
      candidateIdentity: candidate.identity,
      generation: 1,
    );
    await repo.stageDiscoverySources(
      candidateIdentity: candidate.identity,
      generation: 1,
      sources: const [
        SourceResult(candidate: candidate, body: '[C]A single chart'),
      ],
    );

    final saved = await repo.saveChosenSongFast(
      prior,
      candidateIdentity: candidate.identity,
      discoveryGeneration: 1,
      existingSongId: prior.id,
      expectedExistingHash: priorHash,
      existingSnapshot: prior,
    );
    expect(saved.changed, isTrue);
    expect(saved.song.body, prior.body);
    expect(saved.song.sources, isEmpty);
    expect((await repo.getSongRaw(legacy.id))!.document.length, lessThan(4096));

    final full = (await repo.getSongWithEvidence(legacy.id))!;
    expect(
      full.sources
          .singleWhere(
            (item) => item.candidate.identity == oldCandidate.identity,
          )
          .body,
      oldEvidence,
    );
    final history = full.extra['previousSavedVersions'] as List;
    final previous = SongDocument.fromJson(jsonMap(history.single));
    expect(previous.sources.single.body, oldEvidence);
  });

  test('version 2 search backfill reads a large document in chunks', () async {
    final directory = await Directory.systemTemp.createTemp(
      'singbook-large-document-',
    );
    final path = '${directory.path}${Platform.pathSeparator}library.db';
    final body = 'Здравствуй 🌍\n' * 150000;
    final document = ChordProCodec().encode(largeSong(body));
    final database = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE songs ('
            'id TEXT PRIMARY KEY, title TEXT NOT NULL, artist TEXT NOT NULL, '
            'album TEXT, favorite INTEGER NOT NULL DEFAULT 0, '
            'document TEXT NOT NULL, content_hash TEXT NOT NULL, '
            'lyric_hash TEXT NOT NULL, source_identity TEXT, '
            'revision INTEGER NOT NULL, created_at TEXT NOT NULL, '
            'updated_at TEXT NOT NULL)',
          );
          await db.insert('songs', {
            'id': 'large',
            'title': 'Large document',
            'artist': 'Regression fixture',
            'favorite': 0,
            'document': document,
            'content_hash': sha256.convert(utf8.encode(document)).toString(),
            'lyric_hash': 'legacy',
            'revision': 0,
            'created_at': DateTime.utc(2020).toIso8601String(),
            'updated_at': DateTime.utc(2020).toIso8601String(),
          });
        },
      ),
    );
    await database.close();

    final upgraded = await LibraryRepository.open(
      path: path,
      factory: databaseFactoryFfi,
    );
    try {
      expect(await upgraded.listSongs(query: 'ЗДРАВСТВУЙ'), hasLength(1));
      expect((await upgraded.getSong('large'))!.body, body);
    } finally {
      await upgraded.close();
      await directory.delete(recursive: true);
    }
  });
}
