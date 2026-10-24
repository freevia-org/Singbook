import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/macos_startup_options.dart';

void main() {
  test('absent option preserves normal selection', () {
    expect(parseMacOSLibraryPath([]), isNull);
    expect(parseMacOSLibraryPath(['--other=value']), isNull);
    expect(parseMacOSLibraryPath(['--library-path-other=/ignored']), isNull);
  });

  test('explicit absolute path preserves spaces and Unicode', () {
    final arguments = List<String>.unmodifiable([
      '--other=value',
      '--library-path',
      '/tmp/QA Музика/fixtures/../library.db',
    ]);
    expect(parseMacOSLibraryPath(arguments), '/tmp/QA Музика/library.db');
    expect(arguments[2], '/tmp/QA Музика/fixtures/../library.db');
    expect(
      parseMacOSLibraryPath(['--library-path=/tmp/QA/library.db']),
      '/tmp/QA/library.db',
    );
  });

  for (final arguments in <List<String>>[
    ['--library-path'],
    ['--library-path='],
    ['--library-path', '   '],
    ['--library-path', '--other'],
    ['--library-path=relative.db'],
    ['--library-path=~/library.db'],
    [r'--library-path=C:\QA\library.db'],
    ['--library-path=/tmp/invalid\u0000.db'],
    ['--library-path=/tmp/one.db', '--library-path=/tmp/two.db'],
    ['--library-path', '/tmp/one.db', '--library-path=/tmp/one.db'],
  ]) {
    test(
      'invalid override fails without normal-library fallback: $arguments',
      () {
        expect(() => parseMacOSLibraryPath(arguments), throwsFormatException);
      },
    );
  }
}
