import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/player/player_screen.dart';
import 'package:singbook/ui/settings/settings_screen.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

// Inspect incremental serialized updates: a settled semantics snapshot can hide
// an orphan node that has already invalidated the native Windows AXTree.
class _RecordingBinding extends AutomatedTestWidgetsFlutterBinding {
  final children = <int, List<int>>{};
  final details = <int, String>{};
  final orphans = <int>[];
  final commits = <List<int>>[];

  @override
  ui.SemanticsUpdateBuilder createSemanticsUpdateBuilder() =>
      _RecordingBuilder(super.createSemanticsUpdateBuilder(), this);

  void commit(Set<int> changed) {
    final reachable = <int>{};
    void visit(int id) {
      if (!reachable.add(id)) return;
      for (final child in children[id] ?? const <int>[]) {
        visit(child);
      }
    }

    visit(0);
    // Old detached nodes may remain in the map; only nodes serialized in this
    // update must be reachable from the current root.
    final missing = changed.where((id) => !reachable.contains(id)).toList();
    commits.add(missing);
    orphans.addAll(missing);
  }
}

class _RecordingBuilder implements ui.SemanticsUpdateBuilder {
  _RecordingBuilder(this.delegate, this.binding);
  final ui.SemanticsUpdateBuilder delegate;
  final _RecordingBinding binding;
  final changed = <int>{};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #updateNode) {
      final args = invocation.namedArguments;
      final id = args[#id] as int;
      changed.add(id);
      binding.details[id] =
          "id=$id label=${args[#label]} children=${args[#childrenInTraversalOrder]}";
      binding.children[id] = List<int>.from(
        args[#childrenInTraversalOrder] as Iterable,
      );
      return Function.apply(delegate.updateNode, [], args);
    }
    if (invocation.memberName == #updateCustomAction) {
      return Function.apply(
        delegate.updateCustomAction,
        [],
        invocation.namedArguments,
      );
    }
    if (invocation.memberName == #build) {
      binding.commit(changed);
      return delegate.build();
    }
    return super.noSuchMethod(invocation);
  }
}

class _Controller extends FakeUiController {
  _Controller() : super((_) => throw UnimplementedError());
  double speed = 1.5;
  double fontSize = 24;

  @override
  VerseUiState get state => VerseUiState(
    song: const SongCardData(
      id: 'fixture',
      title: 'Original fixture',
      durationSeconds: 60,
    ),
    activeTab: VerseTab.settings,
    playbackSpeed: speed,
    lyricsFontSize: fontSize,
  );

  @override
  Future<void> setPlaybackSpeed(double value) async {
    speed = value;
    refresh();
  }

  @override
  Future<void> setLyricsFontSize(double value) async {
    fontSize = value;
    refresh();
  }
}

void main() {
  final binding = _RecordingBinding();
  for (final control in ['appearance', 'seek', 'speed']) {
    testWidgets(
      '$control slider preserves connected Windows semantics',
      (tester) async {
        binding.children.clear();
        binding.details.clear();
        binding.orphans.clear();
        binding.commits.clear();
        final handle = tester.ensureSemantics();
        final controller = _Controller();
        addTearDown(controller.dispose);
        try {
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: singbookLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: control == 'appearance'
                  ? SettingsScreen(controller: controller)
                  : Builder(
                      builder: (context) => Scaffold(
                        body: ElevatedButton(
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                body: PlayerScreen(controller: controller),
                              ),
                            ),
                          ),
                          child: const Text('Open player'),
                        ),
                      ),
                    ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(control == 'appearance' ? 'Appearance' : 'Open player'),
          );
          await tester.pumpAndSettle();
          if (control == 'speed') {
            await tester.tap(find.byKey(const ValueKey('scroll-speed-toggle')));
            await tester.pumpAndSettle();
          }
          final slider = switch (control) {
            'speed' => find.byKey(const ValueKey('scroll-speed-slider')),
            'seek' => find.byKey(const ValueKey('player-seek-slider')),
            _ => find.byType(Slider),
          };
          SemanticsNode? adjustable;
          void visit(SemanticsNode node) {
            if (node.getSemanticsData().hasAction(
              ui.SemanticsAction.increase,
            )) {
              adjustable = node;
            }
            node.visitChildren((child) {
              visit(child);
              return true;
            });
          }

          visit(tester.getSemantics(slider));
          expect(adjustable, isNotNull);
          final node = adjustable!;
          expect(
            node.getSemanticsData().hasAction(ui.SemanticsAction.increase),
            isTrue,
          );
          expect(
            node.getSemanticsData().hasAction(ui.SemanticsAction.decrease),
            isTrue,
          );
          final initialValue = tester.widget<Slider>(slider).value;
          node.owner!.performAction(node.id, ui.SemanticsAction.increase);
          await tester.pumpAndSettle();
          if (control == 'appearance') {
            expect(controller.fontSize, greaterThan(initialValue));
          } else if (control == 'speed') {
            expect(controller.speed, greaterThan(initialValue));
          } else {
            expect(
              controller.calls.any((call) => call.startsWith('seek(')),
              isTrue,
            );
          }
          await tester.drag(
            slider,
            control == 'speed' ? const Offset(0, -25) : const Offset(25, 0),
          );
          await tester.pumpAndSettle();
          // Inspect opening, interaction, overlay dismissal and route removal.
          if (control == 'speed') {
            Navigator.of(tester.element(slider)).pop();
            await tester.pumpAndSettle();
          }
          await tester.pageBack();
          await tester.pumpAndSettle();
          expect(binding.commits.length, greaterThan(2));
          expect(
            binding.orphans,
            isEmpty,
            reason:
                'Every serialized node must be reachable: ${binding.orphans.map((id) => [binding.details[id], ...(binding.children[id] ?? []).map((c) => binding.details[c])]).toList()}',
          );
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          handle.dispose();
        }
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );
  }
}
