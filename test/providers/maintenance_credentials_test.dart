import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/maintenance_credentials.dart';

void main() {
  late Directory original, temporary;
  late File app, maintenance;
  setUp(() async {
    original = Directory.current;
    temporary = await Directory.systemTemp.createTemp(
      'singbook-credentials-test-',
    );
    await Directory('${temporary.path}/config').create();
    app = File('${temporary.path}/config/local.defines.json');
    maintenance = File('${temporary.path}/config/maintenance.defines.json');
    await app.writeAsString('{"GENIUS_ACCESS_TOKEN":"synthetic-app"}');
    Directory.current = temporary;
  });
  tearDown(() async {
    Directory.current = original;
    final resolved = await temporary.resolveSymbolicLinks();
    final parent = await Directory.systemTemp.resolveSymbolicLinks();
    if (!resolved.startsWith(
      '$parent${Platform.pathSeparator}singbook-credentials-test-',
    )) {
      throw StateError('Refusing cleanup outside owned test directory');
    }
    await temporary.delete(recursive: true);
  });

  String read({
    Map<String, String> environment = const {},
    String compiled = '',
  }) =>
      maintenanceGeniusToken(environment: environment, compiledToken: compiled);

  test(
    'missing maintenance credential never falls back to app build token',
    () {
      expect(read(), isEmpty);
      expect(app.readAsStringSync(), '{"GENIUS_ACCESS_TOKEN":"synthetic-app"}');
    },
  );

  test(
    'separate maintenance file wins without modifying app configuration',
    () async {
      await maintenance.writeAsString(
        '{"GENIUS_ACCESS_TOKEN":"synthetic-maintenance"}',
      );
      expect(read(), 'synthetic-maintenance');
      expect(app.readAsStringSync(), '{"GENIUS_ACCESS_TOKEN":"synthetic-app"}');
    },
  );

  test(
    'hosted environment credential takes precedence over local and compiled',
    () async {
      await maintenance.writeAsString(
        '{"GENIUS_ACCESS_TOKEN":"synthetic-maintenance"}',
      );
      expect(
        read(
          environment: {'GENIUS_ACCESS_TOKEN': 'synthetic-cloud'},
          compiled: 'synthetic-compiled',
        ),
        'synthetic-cloud',
      );
    },
  );

  test(
    'explicit compiled maintenance credential precedes local file',
    () async {
      await maintenance.writeAsString(
        '{"GENIUS_ACCESS_TOKEN":"synthetic-maintenance"}',
      );
      expect(read(compiled: 'synthetic-compiled'), 'synthetic-compiled');
    },
  );

  test('empty environment falls through to maintenance file only', () async {
    await maintenance.writeAsString(
      '{"GENIUS_ACCESS_TOKEN":"synthetic-maintenance"}',
    );
    expect(
      read(environment: {'GENIUS_ACCESS_TOKEN': ''}),
      'synthetic-maintenance',
    );
  });

  test(
    'malformed or wrongly typed maintenance file remains not configured',
    () async {
      for (final value in [
        'not-json',
        '[]',
        '{}',
        '{"GENIUS_ACCESS_TOKEN":123}',
      ]) {
        await maintenance.writeAsString(value);
        expect(read(), isEmpty);
      }
    },
  );
}
