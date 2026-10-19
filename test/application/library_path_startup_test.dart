import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:sqflite/sqflite.dart' as sqlite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Paths extends PathProviderPlatform {
  _Paths(this.path);
  final String path;
  int calls = 0;
  @override
  Future<String?> getApplicationSupportPath() async {
    calls++;
    return path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;
  late _Paths fakePaths;
  late PathProviderPlatform originalPaths;
  late sqlite.DatabaseFactory? originalFactory;
  late TargetPlatform? originalPlatform;
  final controllers = <AppController>[];

  AppController controller({String? path}) {
    final app = AppController(
      repositoryPath: path,
      discovery: SourceDiscoveryService(const []),
    );
    controllers.add(app);
    return app;
  }

  Future<void> close(AppController app) async {
    final db = app.repository.database;
    app.dispose();
    controllers.remove(app);
    for (var i = 0; i < 1000 && db.isOpen; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(
      db.isOpen,
      isFalse,
      reason: 'The controller owns the path-opened DB.',
    );
  }

  setUp(() async {
    sqfliteFfiInit();
    temporary = await Directory.systemTemp.createTemp('singbook-path-startup-');
    originalFactory = sqlite.databaseFactoryOrNull;
    sqlite.databaseFactory = databaseFactoryFfiNoIsolate;
    originalPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    originalPaths = PathProviderPlatform.instance;
    fakePaths = _Paths(paths.join(temporary.path, 'default-support'));
    PathProviderPlatform.instance = fakePaths;
  });
  tearDown(() async {
    for (final app in controllers.toList()) {
      await close(app);
    }
    PathProviderPlatform.instance = originalPaths;
    debugDefaultTargetPlatformOverride = originalPlatform;
    sqlite.databaseFactoryOrNull = originalFactory;
    await temporary.delete(recursive: true);
  });

  test(
    'an explicit startup path persists and closes its owned library',
    () async {
      final path = paths.join(temporary.path, 'Original library.sqlite');
      final first = controller(path: path);
      await first.initialize();
      await first.saveSong(
        SongDocument(
          id: 'original-fixture',
          title: 'Original fixture',
          artist: 'Test artist',
          body: '[C]An original fixture line',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );
      await first.setSetting('showChords', false);
      await close(first);
      expect(fakePaths.calls, 0);

      final reopened = controller(path: path);
      await reopened.initialize();
      expect(reopened.songs.single.id, 'original-fixture');
      expect(reopened.songs.single.body, '[C]An original fixture line');
      expect(reopened.settings['showChords'], isFalse);
      expect(fakePaths.calls, 0);
    },
  );

  test(
    'the default library and an opt-in disposable library stay separate',
    () async {
      final normal = controller();
      await normal.initialize();
      await normal.setSetting('palette', 'sentinel-default-library');
      await close(normal);
      expect(fakePaths.calls, 1);

      final disposable = controller(
        path: paths.join(temporary.path, 'qa.sqlite'),
      );
      await disposable.initialize();
      expect(disposable.settings['palette'], isNot('sentinel-default-library'));
      await disposable.setSetting('palette', 'sentinel-disposable-library');
      await close(disposable);
      expect(fakePaths.calls, 1);

      final normalAgain = controller();
      await normalAgain.initialize();
      expect(normalAgain.settings['palette'], 'sentinel-default-library');
      expect(fakePaths.calls, 2);
    },
  );

  test(
    'injected repositories cannot silently ignore an explicit path',
    () async {
      final repository = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfiNoIsolate,
      );
      try {
        expect(
          () => AppController(repository: repository, repositoryPath: 'other'),
          throwsArgumentError,
        );
        expect(repository.database.isOpen, isTrue);
      } finally {
        await repository.close();
      }
    },
  );
}
