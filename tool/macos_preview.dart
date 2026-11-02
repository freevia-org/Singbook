// Disposable native desktop visual acceptance. Never opens the default library.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/ui/verse_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isMacOS) throw UnsupportedError('macOS acceptance only');
  final directory = await getTemporaryDirectory();
  final repository = await LibraryRepository.open(
    path:
        '${directory.path}/macos-preview-${DateTime.now().microsecondsSinceEpoch}.db',
  );
  for (var i = 0; i < 6; i++) {
    await repository.saveSong(
      SongDocument(
        id: 'macos-qa-$i',
        title: i == 0 ? 'A Lantern Original' : 'Rehearsal Song $i',
        artist: 'Freevia QA',
        body:
            '{start_of_verse: Verse}\n[C]Morning light along the road\n'
            '[G]We sing a new refrain\n{end_of_verse}\n'
            '{start_of_chorus: Chorus}\n[F]Carry the lantern [C]home\n'
            '[G]نحمل ضوء الصباح\n{end_of_chorus}',
      ),
    );
  }
  await repository.saveSetlist(
    SetlistDocument(
      id: 'macos-qa-setlist',
      name: 'Lantern Rehearsal',
      entries: [
        for (var i = 0; i < 6; i++)
          SetlistEntry(id: 'entry-$i', songId: 'macos-qa-$i'),
      ],
    ),
  );
  final app = AppController(
    repository: repository,
    discovery: SourceDiscoveryService(const []),
  );
  await app.initialize();
  await app.setSetting(
    'locale',
    const String.fromEnvironment('QA_LOCALE', defaultValue: 'en'),
  );
  await app.setSetting(
    'themeMode',
    const String.fromEnvironment('QA_THEME', defaultValue: 'light'),
  );
  runApp(VerseApp(controller: app));
}
