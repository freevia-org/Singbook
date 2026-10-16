import 'dart:convert';
import 'dart:io';

/// Maintenance has its own ignored configuration. Never borrow the app token.
String maintenanceGeniusToken({
  Map<String, String>? environment,
  String compiledToken = const String.fromEnvironment('GENIUS_ACCESS_TOKEN'),
  File? configuration,
}) {
  final injected = (environment ?? Platform.environment)['GENIUS_ACCESS_TOKEN'];
  if (injected != null && injected.isNotEmpty) return injected;
  if (compiledToken.isNotEmpty) return compiledToken;
  final local = configuration ?? File('config/maintenance.defines.json');
  try {
    if (!local.existsSync()) return '';
    final decoded = jsonDecode(local.readAsStringSync());
    return decoded is Map && decoded['GENIUS_ACCESS_TOKEN'] is String
        ? decoded['GENIUS_ACCESS_TOKEN'] as String
        : '';
  } catch (_) {
    // Missing, malformed or unreadable private configuration is not configured.
    return '';
  }
}
