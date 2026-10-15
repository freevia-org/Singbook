import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';

void main() {
  sqfliteFfiInit();
  late LibraryRepository repository;
  late AppController app;
  late AppControllerAdapter ui;
  final printed = <SongDocument>[];
  final sharedPdfs = <SongDocument>[];

  setUp(() async {
    printed.clear();
    sharedPdfs.clear();
    repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    app = AppController(repository: repository);
    await app.initialize();
    ui = AppControllerAdapter(
      app,
      onPrintSong: (song) async => printed.add(song),
      onShareSongPdf: (song) async => sharedPdfs.add(song),
    );
    await app.saveSong(_song());
    await app.saveSong(
      _song(id: 'other', title: 'Other', body: '[Am]Other line'),
    );
    await app.saveSetlist(
      SetlistDocument(
        id: 'setlist',
        name: 'Setlist',
        entries: const [
          SetlistEntry(
            id: 'entry',
            songId: 'song',
            overrides: {'key': 'D', 'capo': 2},
          ),
        ],
      ),
    );
  });

  tearDown(() async {
    ui.dispose();
    app.dispose();
    await repository.close();
  });

  test(
    'reader PDF exports use the active transposed arrangement only',
    () async {
      await ui.openSetlistEntry('setlist', 'entry');
      expect(ui.state.readerKey, 'D');
      expect(ui.state.readerCapo, '2');

      await ui.printSong('song');
      expect(printed.single.body, '[D]First line\n[A]Second line');
      expect(printed.single.metadata['key'], 'D');
      expect(printed.single.metadata['capo'], 2);

      await ui.transpose(1);
      await ui.shareSongPdf('song');
      expect(sharedPdfs.single.body, '[D#]First line\n[A#]Second line');
      expect(sharedPdfs.single.metadata['key'], 'D#');
      expect(sharedPdfs.single.metadata['capo'], 2);

      final saved = app.findSong('song')!;
      expect(saved.body, '[C]First line\n[G]Second line');
      expect(saved.metadata['key'], 'C');
      expect(saved.metadata['capo'], 1);

      await ui.printSong('other');
      expect(printed.last.body, '[Am]Other line');
      expect(printed.last.metadata, {'key': 'Am', 'capo': 0});

      await ui.openSong('song');
      await ui.transpose(1);
      await ui.printSong('song');
      expect(printed.last.body, '[C#]First line\n[G#]Second line');
      expect(printed.last.metadata['key'], 'C#');
      expect(printed.last.metadata['capo'], 1);

      ui.setTab(VerseTab.songs);
      await ui.printSong('song');
      expect(printed.last.body, '[C]First line\n[G]Second line');
      expect(printed.last.metadata['key'], 'C');
      expect(printed.last.metadata['capo'], 1);
      expect(app.findSong('song')!.body, '[C]First line\n[G]Second line');
    },
  );
}

SongDocument _song({
  String id = 'song',
  String title = 'Song',
  String body = '[C]First line\n[G]Second line',
}) => SongDocument(
  id: id,
  title: title,
  artist: 'Artist',
  body: body,
  metadata: {'key': id == 'song' ? 'C' : 'Am', 'capo': id == 'song' ? 1 : 0},
);
