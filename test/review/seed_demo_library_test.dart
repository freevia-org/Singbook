import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/models.dart';

void main() {
  test(
    'seed a new isolated demonstration library only when explicitly requested',
    () async {
      final path = Platform.environment['SINGBOOK_DEMO_DATABASE'];
      if (path == null) return;
      if (File(path).existsSync()) {
        throw StateError('Refusing to overwrite an existing library');
      }
      sqfliteFfiInit();
      final repository = await LibraryRepository.open(
        path: path,
        factory: databaseFactoryFfi,
      );
      try {
        const fixtures = [
          'harbor-road',
          'morning-paper',
          'after-the-rain',
          'open-sky',
        ];
        final songs = <SongDocument>[];
        for (final fixture in fixtures) {
          final song = ChordProCodec().decode(
            File('docs/testflight-fixtures/$fixture.cho').readAsStringSync(),
          );
          await repository.saveSong(song);
          songs.add(song);
        }
        await repository.saveSetlist(
          SetlistDocument(
            id: 'freevia-demo-set',
            name: 'Freevia Demo Set',
            entries: [
              for (var index = 0; index < songs.length; index++)
                SetlistEntry(id: 'demo-entry-$index', songId: songs[index].id),
            ],
          ),
        );
        await repository.setSetting('app', {
          'locale': 'en',
          'startupSongsView': 'library',
        });
        expect(
          (await repository.listSongs()).map((song) => song.title),
          unorderedEquals([
            'Harbor Road',
            'Morning Paper',
            'After the Rain',
            'Open Sky',
          ]),
        );
      } finally {
        await repository.close();
      }
    },
  );
}
