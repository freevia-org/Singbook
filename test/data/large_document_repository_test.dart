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
