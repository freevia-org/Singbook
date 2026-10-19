import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:singbook/data/library_database.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:sqflite/sqflite.dart' as sqlite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _SupportDirectory extends PathProviderPlatform {
  _SupportDirectory(this.directory);
  final String directory;
  int calls = 0;

  @override
  Future<String?> getApplicationSupportPath() async {
    calls++;
    return directory;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;
  late _SupportDirectory support;
  late PathProviderPlatform originalPaths;
  late sqlite.DatabaseFactory? originalFactory;
  late String originalDatabasePath;
  late TargetPlatform? originalPlatform;

  setUp(() async {
    sqfliteFfiInit();
    temporary = await Directory.systemTemp.createTemp('singbook-windows-db-');
    originalPaths = PathProviderPlatform.instance;
    originalFactory = sqlite.databaseFactoryOrNull;
    originalPlatform = debugDefaultTargetPlatformOverride;
    originalDatabasePath = await databaseFactoryFfiNoIsolate.getDatabasesPath();
    await databaseFactoryFfiNoIsolate.setDatabasesPath(
      paths.join(temporary.path, 'existing-databases'),
    );
    sqlite.databaseFactory = databaseFactoryFfiNoIsolate;
    support = _SupportDirectory(paths.join(temporary.path, 'app-support'));
    PathProviderPlatform.instance = support;
  });

  tearDown(() async {
    sqlite.databaseFactoryOrNull = originalFactory;
    debugDefaultTargetPlatformOverride = originalPlatform;
    PathProviderPlatform.instance = originalPaths;
    await databaseFactoryFfiNoIsolate.setDatabasesPath(originalDatabasePath);
    await temporary.delete(recursive: true);
  });

  test(
    'Windows default factory and support path persist the library',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      initializeLibraryDatabase();
      expect(sqlite.databaseFactory, same(databaseFactoryFfi));

      final location = paths.join(
        support.directory,
        'databases',
        'verse_library.db',
      );
      expect(await Directory(paths.dirname(location)).exists(), isFalse);
      var repository = await LibraryRepository.open();
      try {
        expect(repository.database.path, location);
        await repository.saveSong(
          SongDocument(
            id: 'persisted-song',
            title: 'Desktop song',
            artist: 'Artist',
            body: '[Em]Saved lyric',
          ),
        );
        await repository.setSetting('player', {'speed': 1.2});
      } finally {
        await repository.close();
      }
      expect(await File(location).exists(), isTrue);

      repository = await LibraryRepository.open();
      try {
        expect(
          (await repository.getSong('persisted-song'))?.body,
          '[Em]Saved lyric',
        );
        expect((await repository.getSetting('player'))['speed'], 1.2);
      } finally {
        await repository.close();
      }
    },
  );

  for (final platform in [
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  ]) {
    test('$platform preserves the existing factory and library path', () async {
      debugDefaultTargetPlatformOverride = platform;
      final factory = sqlite.databaseFactory;
      final location = paths.join(
        await factory.getDatabasesPath(),
        'verse_library.db',
      );
      var repository = await LibraryRepository.open();
      try {
        await repository.setSetting('existing-library', {'preserved': true});
      } finally {
        await repository.close();
      }

      initializeLibraryDatabase();
      expect(sqlite.databaseFactory, same(factory));
      repository = await LibraryRepository.open();
      try {
        expect(repository.database.path, location);
        expect(
          (await repository.getSetting('existing-library'))['preserved'],
          true,
        );
        expect(support.calls, 0);
      } finally {
        await repository.close();
      }
    });
  }

  test(
    'Windows respects explicit paths and injected factory defaults',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      initializeLibraryDatabase();
      final explicitPath = paths.join(temporary.path, 'custom.db');
      final explicit = await LibraryRepository.open(path: explicitPath);
      try {
        expect(explicit.database.path, explicitPath);
      } finally {
        await explicit.close();
      }
      final injected = await LibraryRepository.open(
        factory: databaseFactoryFfiNoIsolate,
      );
      try {
        expect(
          injected.database.path,
          paths.join(
            await databaseFactoryFfiNoIsolate.getDatabasesPath(),
            'verse_library.db',
          ),
        );
        expect(support.calls, 0);
      } finally {
        await injected.close();
      }
    },
  );
}
