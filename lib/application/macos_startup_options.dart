import 'package:path/path.dart' as paths;

/// Explicit isolated QA library. Parsing never opens or creates a database.
String? parseMacOSLibraryPath(List<String> arguments) {
  const flag = '--library-path';
  String? selected;
  var seen = false;
  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (argument != flag && !argument.startsWith('$flag=')) continue;
    if (seen) throw const FormatException('Duplicate --library-path option.');
    seen = true;
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
    if (value.trim().isEmpty ||
        value.contains('\u0000') ||
        !paths.posix.isAbsolute(value)) {
      throw const FormatException(
        '--library-path requires an absolute macOS path.',
      );
    }
    selected = paths.posix.normalize(value);
  }
  return selected;
}
