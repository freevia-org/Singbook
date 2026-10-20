import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/windows_startup_options.dart';

void main() {
  test('absent option preserves normal selection on every platform', () {
    for (final windows in [true, false]) {
      for (final web in [true, false]) {
        expect(
          parseWindowsLibraryPath([], isWindows: windows, isWeb: web),
          isNull,
        );
        expect(
          parseWindowsLibraryPath(
            ['--verbose', '--dart-flags=--foo', 'unused'],
            isWindows: windows,
            isWeb: web,
          ),
          isNull,
        );
      }
    }
  });

  test(
    'separate value preserves Unicode and spaces and normalizes Windows separators',
    () {
      expect(
        parseWindowsLibraryPath([
          '--library-path',
          r'E:\QA Музика\Нова бібліотека\library.db',
        ], isWindows: true),
        r'E:\QA Музика\Нова бібліотека\library.db',
      );
      expect(
        parseWindowsLibraryPath([
          '--library-path',
          'C:/QA/fixtures/../library.db',
        ], isWindows: true),
        r'C:\QA\library.db',
      );
    },
  );

  test('equals form accepts drive absolute and UNC paths', () {
    expect(
      parseWindowsLibraryPath([
        r'--library-path=C:\QA\library.db',
      ], isWindows: true),
      r'C:\QA\library.db',
    );
    expect(
      parseWindowsLibraryPath([
        r'--library-path=\\server\shared songs\Музика\library.db',
      ], isWindows: true),
      r'\\server\shared songs\Музика\library.db',
    );
    expect(
      parseWindowsLibraryPath([
        '--library-path=//server/share/folder/../library.db',
      ], isWindows: true),
      r'\\server\share\library.db',
    );
  });

  test('unknown arguments remain unchanged around an explicit option', () {
    final arguments = List<String>.unmodifiable([
      '--trace-startup',
      '--library-path',
      r'C:\QA\library.db',
      '--other=value',
    ]);
    expect(
      parseWindowsLibraryPath(arguments, isWindows: true),
      r'C:\QA\library.db',
    );
    expect(arguments, [
      '--trace-startup',
      '--library-path',
      r'C:\QA\library.db',
      '--other=value',
    ]);
    expect(
      parseWindowsLibraryPath([
        '--library-path-other=C:/ignored.db',
      ], isWindows: true),
      isNull,
    );
  });

  for (final arguments in <List<String>>[
    ['--library-path'],
    ['--library-path='],
    ['--library-path', ''],
    ['--library-path', '   '],
    ['--library-path', '--verbose'],
    ['--library-path', 'relative.db'],
    ['--library-path=folder/library.db'],
    [r'--library-path=C:library.db'],
    [r'--library-path=\library.db'],
    ['--library-path=/library.db'],
    [r'--library-path=\\server'],
    ['--library-path=C:/QA/invalid\u0000.db'],
    [r'--library-path=C:\one.db', r'--library-path=C:\two.db'],
    ['--library-path', r'C:\one.db', '--library-path', r'C:\two.db'],
    [r'--library-path=C:\one.db', '--library-path', r'C:\one.db'],
  ]) {
    test(
      'invalid explicit option fails rather than falling back: $arguments',
      () {
        expect(
          () => parseWindowsLibraryPath(arguments, isWindows: true),
          throwsFormatException,
        );
      },
    );
  }

  test('explicit option rejects non-Windows and web without a fallback', () {
    for (final arguments in <List<String>>[
      ['--library-path', r'C:\QA\library.db'],
      [r'--library-path=C:\QA\library.db'],
    ]) {
      expect(
        () => parseWindowsLibraryPath(arguments, isWindows: false),
        throwsArgumentError,
      );
      expect(
        () => parseWindowsLibraryPath(arguments, isWindows: true, isWeb: true),
        throwsArgumentError,
      );
    }
  });
}
