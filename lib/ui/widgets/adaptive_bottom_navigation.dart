import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Keeps complete destination names readable with large system text.
class AdaptiveBottomNavigation extends StatelessWidget {
  const AdaptiveBottomNavigation({
    super.key,
    required this.labels,
    required this.icons,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final List<IconData> icons;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final style =
        theme.navigationBarTheme.labelTextStyle?.resolve({}) ??
        theme.textTheme.labelMedium!.copyWith(fontSize: 14);
    return LayoutBuilder(
      builder: (context, constraints) {
        final widths = labels.map((label) {
          final painter = TextPainter(
            text: TextSpan(text: label, style: style),
            textDirection: Directionality.of(context),
            textScaler: scaler,
          )..layout();
          return painter.width;
        });
        if (widths.every((width) => width + 16 <= constraints.maxWidth / 4)) {
          return NavigationBar(
            height: 80 + ((scaler.scale(14) / 14 - 1).clamp(0, 2) * 48),
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            destinations: [
              for (var i = 0; i < labels.length; i++)
                NavigationDestination(icon: Icon(icons[i]), label: labels[i]),
            ],
          );
        }
        return Material(
          color: theme.colorScheme.surfaceContainer,
          child: SafeArea(
            top: false,
            child: Column(
              key: const ValueKey('two-row-navigation'),
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var row = 0; row < 2; row++)
                  Row(
                    children: [
                      for (var i = row * 2; i < row * 2 + 2; i++)
                        Expanded(
                          child: Semantics(
                            key: ValueKey('navigation-tile-$i'),
                            selected: i == selectedIndex,
                            button: true,
                            label: labels[i],
                            child: InkWell(
                              onTap: () => onSelected(i),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: math.max(
                                    64,
                                    scaler.scale(14) * 2 + 20,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: i == selectedIndex
                                              ? theme
                                                    .colorScheme
                                                    .secondaryContainer
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                        child: ExcludeSemantics(
                                          child: Icon(icons[i], size: 24),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ExcludeSemantics(
                                        child: Text(
                                          labels[i],
                                          key: ValueKey('navigation-label-$i'),
                                          textAlign: TextAlign.center,
                                          style: style,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
