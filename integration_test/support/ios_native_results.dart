import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// Records the integration binding's actual outcomes for headless simulators.
/// This complements the normal Flutter test driver; it never replaces failures.
void recordIosNativeResults() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const session = String.fromEnvironment('SINGBOOK_NATIVE_SESSION');
  if (session.isEmpty) return;
  if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(session)) {
    throw ArgumentError.value(session, 'SINGBOOK_NATIVE_SESSION');
  }
  tearDownAll(() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/singbook-native-results');
    await directory.create(recursive: true);
    final outcomes = binding.results.map(
      (name, value) => MapEntry(name, value.toString()),
    );
    final view = binding.platformDispatcher.views.first;
    await File('${directory.path}/$session.json').writeAsString(
      jsonEncode({
        'session': session,
        'platform': Platform.operatingSystem,
        'physicalWidth': view.physicalSize.width,
        'physicalHeight': view.physicalSize.height,
        'tests': outcomes,
        'allTestsPassed':
            outcomes.isNotEmpty &&
            outcomes.values.every((value) => value == 'success') &&
            binding.failureMethodsDetails.isEmpty,
        'failures': binding.failureMethodsDetails
            .map((failure) => failure.details)
            .toList(),
      }),
      flush: true,
    );
  });
}
