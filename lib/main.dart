import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;
import 'application/error_reporting.dart';
import 'ui/verse_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
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
  runApp(const VerseApp());
}
