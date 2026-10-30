// Deterministic native contracts: no live accounts or provider availability.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'ios_platform_device_test.dart' as platform;
import 'ios_provider_parity_device_test.dart' as providers;
import 'support/ios_native_results.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  // Let the native scene attach its accessibility connection before tests
  // record their SemanticsHandle baseline (also needed by headless launches).
  setUpAll(() async {
    runApp(
      const MaterialApp(home: Scaffold(body: Text('Preparing native QA'))),
    );
    await binding.delayed(const Duration(milliseconds: 500));
  });
  platform.main();
  providers.main();
  recordIosNativeResults();
}
