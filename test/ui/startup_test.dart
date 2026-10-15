import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/ui/verse_app.dart';

void main() {
  testWidgets('a library that cannot be opened shows a localized message', (
    tester,
  ) async {
    final repository = _BrokenRepository();
    final app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService(const []),
    );
    addTearDown(app.dispose);

    await tester.pumpWidget(VerseApp(controller: app));
    await tester.pumpAndSettle();

    expect(find.text('Your library could not be opened.'), findsOneWidget);
    expect(
      find.textContaining('secret'),
      findsNothing,
      reason: 'raw exception text must not reach the screen',
    );
    final attempts = repository.attempts;
    expect(attempts, greaterThan(0));

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(repository.attempts, greaterThan(attempts));
    expect(find.text('Your library could not be opened.'), findsOneWidget);
  });

  testWidgets('an injected controller is not disposed with the app', (
    tester,
  ) async {
    final app = AppController(
      repository: _BrokenRepository(),
      discovery: SourceDiscoveryService(const []),
    );
    addTearDown(app.dispose);

    await tester.pumpWidget(VerseApp(controller: app));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());

    // Adding a listener to a disposed ChangeNotifier asserts.
    void listener() {}
    app.addListener(listener);
    app.removeListener(listener);
  });
}

class _BrokenRepository implements LibraryRepository {
  int attempts = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    attempts++;
    throw StateError('secret database path');
  }
}
