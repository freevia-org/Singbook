import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/extra/roswell.dart';
import 'package:singbook/providers/transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  test(
    'individual Roswell search, save, reopen and export preserve chart evidence',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'singbook-roswell-import-',
      );
      final dbPath = '${directory.path}/library.db';
      var repo = await LibraryRepository.open(
        path: dbPath,
        factory: databaseFactoryFfi,
      );
      final archive = Archive();
      const raw =
          '{title: Amber Lantern}\n{artist: Synthetic Ensemble}\n'
          '{key: C}\n{capo: 2}\n{tempo: 96}\n{book: Americana}\n'
          '{composer: Synthetic Writer}\n{comment: Verse}\n'
          '[C]Paper lanterns float across the [G]sleeping garden\n'
          '[Am]Silver rivers carry every [F]quiet song\n'
          '[C]Morning opens all the windows [G]to the sky';
      archive.add(ArchiveFile.string('amber-lantern.chordpro', raw));
      archive.add(
        ArchiveFile.string(
          'unselected.chordpro',
          '{title: Other chart}\n{artist: Someone Else}\n[D]Other words',
        ),
      );
      final bytes = ZipEncoder().encodeBytes(archive);
      var requests = 0;
      final transport = ProviderTransport(
        client: MockClient((r) async {
          requests++;
          return r.url.path == '/songbooks'
              ? http.Response(
                  '<a href="/_files/archives/synthetic.zip?dn=rmj-all-chordpro-20261026_120000-EST.zip">ChordPro</a>',
                  200,
                )
              : http.Response.bytes(bytes, 200);
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      final provider = RoswellMusicJamProvider(transport);
      await repo.setSetting('app', {
        'providers': {'roswellmusicjam': true},
      });
      final app = AppController(
        repository: repo,
        discovery: SourceDiscoveryService([provider]),
      );
      try {
        await app.initialize();
        await app.search('Amber Lantern Synthetic Ensemble');
        final candidate = app.suggestions.single;
        expect(candidate.id, 'amber-lantern.chordpro');
        await app.selectCandidate(candidate);
        final source = app.results.single;
        expect(source.hasChords, true);
        final saved = await app.saveResult(source: source);
        expect(
          (await repo.listSongs()).length,
          1,
          reason: 'only selected chart enters library',
        );
        expect(saved.title, candidate.title);
        expect(saved.metadata['capo'], 2);
        expect(saved.metadata['tempo'], 96);
        expect(saved.metadata['sourceCollections'], ['Americana']);
        final expectedHash = await repo.getSongHash(saved.id);
        final exported = app.exportSong(saved);
        final decoded = ChordProCodec().decode(exported);
        expect(decoded.id, saved.id);
        expect(decoded.body, saved.body);
        expect(decoded.sources.single.toJson(), saved.sources.single.toJson());
        expect(
          decoded.sources.single.extra['rights']['permissions']['status'],
          'unknown',
        );
        expect(
          utf8.decode(
            base64Decode(
              decoded.sources.single.extra['originalPayload']['base64'],
            ),
          ),
          raw,
        );
        await repo.close();
        repo = await LibraryRepository.open(
          path: dbPath,
          factory: databaseFactoryFfi,
        );
        final reopened = (await repo.listSongs()).single;
        expect(reopened.id, saved.id);
        expect(await repo.getSongHash(reopened.id), expectedHash);
        expect(reopened.body, saved.body);
        expect(reopened.sources.single.toJson(), saved.sources.single.toJson());
        expect(
          requests,
          2,
          reason: 'search, discovery and save reuse one archive',
        );
      } finally {
        app.dispose();
        await transport.close();
        await repo.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
