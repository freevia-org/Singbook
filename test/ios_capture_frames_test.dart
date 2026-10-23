import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Exercise the idle live-binding frame path that the iOS capture helper uses.
void main() {
  final binding = LiveTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('idle live binding draws all three capture fade frames', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();
    var drawn = 0;
    for (var frame = 0; frame < 3; frame++) {
      binding.addPostFrameCallback((_) => drawn++);
      await binding.pump(const Duration(milliseconds: 16))
          .timeout(const Duration(seconds: 2));
    }
    expect(drawn, 3);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 15)));
}
