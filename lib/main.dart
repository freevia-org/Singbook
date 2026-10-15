import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'application/error_reporting.dart';
import 'ui/verse_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  installErrorHandlers();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Noto Sans',
      'Noto Sans Mono',
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
