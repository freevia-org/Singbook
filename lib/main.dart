import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'application/error_reporting.dart';
import 'application/windows_startup_options.dart';
import 'data/library_database.dart';
import 'ui/verse_app.dart';

void main(List<String> arguments) {
  final libraryPath = parseWindowsLibraryPath(
    arguments,
    isWindows: !kIsWeb && defaultTargetPlatform == TargetPlatform.windows,
    isWeb: kIsWeb,
  );
  WidgetsFlutterBinding.ensureInitialized();
  initializeLibraryDatabase();
  installErrorHandlers();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Noto Sans',
      'Noto Sans Mono',
      'Noto Sans Arabic',
      'Noto Sans Hebrew',
      'Noto Sans Devanagari',
      'Noto Sans Thai',
      'Noto Sans SC (subset)',
      'Noto Sans KR (Hangul subset)',
    ], await rootBundle.loadString('assets/fonts/LICENSE'));
    yield LicenseEntryWithLineBreaks(
      ['Singbook Brand (derived from Libre Baskerville)'],
      await rootBundle.loadString('assets/fonts/LibreBaskerville-LICENSE.txt'),
    );
    yield LicenseEntryWithLineBreaks([
      'Singbook Serif (derived from Lora)',
    ], await rootBundle.loadString('assets/fonts/SingbookSerif-OFL.txt'));
  });
  runApp(VerseApp(libraryPath: libraryPath));
}
