import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as paths;
import 'package:path_provider/path_provider.dart';

final _captureSession = DateTime.now().microsecondsSinceEpoch.toString();

/// Capture before advancing the test; host log/simctl timing can lag on iOS.
Future<bool> captureIosCheckpoint(String name) async {
  if (!Platform.isIOS) return false;
  assert(RegExp(r'^[\w-]+$').hasMatch(name));
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Live test bindings paint a short-lived crosshair after synthetic taps.
  // Render its fade frames before recording the actual app appearance.
  for (var frame = 0; frame < 3; frame++) {
    await binding.pump(const Duration(milliseconds: 16));
  }
  final bytes = await binding.takeScreenshot(name);
  try {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(
      paths.join(support.path, 'singbook-e2e-captures', _captureSession),
    );
    await directory.create(recursive: true);
    await File(
      paths.join(directory.path, '$name.png'),
    ).writeAsBytes(bytes, flush: true);
    debugPrint('SINGBOOK_E2E_NATIVE_CAPTURE:$_captureSession:$name');
  } finally {
    // Files carry the evidence. Avoid duplicating every PNG in VM result JSON.
    binding.reportData?.remove('screenshots');
  }
  return true;
}
