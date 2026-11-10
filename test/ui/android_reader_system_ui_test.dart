import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/player/player_full_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('org.freevia.singbook/fullscreen');

  testWidgets(
    'Android reader keeps nav immersive, promotes landscape/fullscreen, restores outside reader',
    (tester) async {
      final calls = <(String, Object?)>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add((call.method, call.arguments));
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );

      final systemUi = PlayerFullScreen();
      systemUi.setReaderState(active: true, fullScreen: false);
      await tester.pump();
      await tester.pump();
      expect(calls, [('setMode', 'reader')]);

      systemUi.setReaderState(active: true, fullScreen: true);
      await tester.pump();
      await tester.pump();
      expect(calls.last, ('setMode', 'fullscreen'));

      systemUi.setReaderState(active: false, fullScreen: false);
      await tester.pump();
      await tester.pump();
      expect(calls.last, ('setMode', 'inactive'));
      systemUi.dispose();
      await tester.pump();
    },
    variant: TargetPlatformVariant({TargetPlatform.android}),
  );
}
