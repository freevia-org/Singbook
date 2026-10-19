import 'package:path/path.dart' as paths;

/// An explicit Windows library override for isolated native runs. Absence of
/// the option leaves the application's normal library selection unchanged.
/// Parsing is pure: it never creates a directory or opens a database.
String? parseWindowsLibraryPath(
  List<String> arguments, {
  required bool isWindows,
  bool isWeb = false,
}) {
  const flag = '--library-path';
  String? selected;
  var seen = false;
  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (argument != flag && !argument.startsWith('$flag=')) continue;
    if (seen) throw const FormatException('Duplicate --library-path option.');
    seen = true;
    if (!isWindows || isWeb) {
      throw ArgumentError('--library-path is supported only on Windows.');
    }
    final String value;
    if (argument.startsWith('$flag=')) {
      value = argument.substring(flag.length + 1);
    } else {
      if (index + 1 >= arguments.length ||
          arguments[index + 1].startsWith('--')) {
        throw const FormatException('Missing value for --library-path.');
      }
      value = arguments[++index];
    }
    if (value.trim().isEmpty || value.contains('\u0000')) {
      throw const FormatException('Invalid value for --library-path.');
    }
    // A rooted Windows path such as \library.db is still drive-relative.
    // Require a drive plus separator, or a UNC server AND share, using Windows
    // semantics even when unit checks run on Linux or macOS.
    final driveAbsolute = RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value);
    final uncAbsolute = RegExp(
      r'^[\\/]{2}[^\\/]+[\\/][^\\/]+(?:[\\/]|$)',
    ).hasMatch(value);
    if (!paths.windows.isAbsolute(value) || (!driveAbsolute && !uncAbsolute)) {
      throw const FormatException(
        '--library-path requires an absolute Windows path.',
      );
    }
    // Normalize the separators before the path package parses the root. Its
    // Windows context otherwise collapses a forward-slash UNC prefix to one
    // backslash, which would turn an absolute share into a drive-relative path.
    selected = paths.windows.normalize(value.replaceAll('/', r'\'));
  }
  return selected;
}
