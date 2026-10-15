import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/theme/verse_theme.dart';

double _luminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG 2.x contrast ratio between two opaque colors.
double contrastRatio(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  final lighter = math.max(la, lb), darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('the contrast helper matches known ratios', () {
    expect(contrastRatio(Colors.black, Colors.white), closeTo(21, .01));
    expect(contrastRatio(Colors.white, Colors.white), closeTo(1, .001));
    // The old light muted color measured about 4.1:1 on the navy paper.
    expect(
      contrastRatio(const Color(0xFF64788A), const Color(0xFFF7F3E9)),
      lessThan(4.5),
    );
  });

  for (final brightness in Brightness.values) {
    for (final palette in versePalettes) {
      test('${palette.name} ${brightness.name} text tokens reach 4.5:1', () {
        final theme = verseTheme(brightness: brightness, palette: palette.name);
        final scheme = theme.colorScheme;
        final surfaces = <String, Color>{
          'surface': scheme.surface,
          'card': verseCardColor(brightness),
          'surfaceContainerLow': scheme.surfaceContainerLow,
          'surfaceContainerHigh': scheme.surfaceContainerHigh,
        };
        final foregrounds = <String, Color>{
          'muted': verseMutedColor(brightness),
          'onSurface': scheme.onSurface,
          'onSurfaceVariant': scheme.onSurfaceVariant,
          'primary': scheme.primary,
          'secondary': scheme.secondary,
        };
        for (final surface in surfaces.entries) {
          for (final foreground in foregrounds.entries) {
            expect(
              contrastRatio(foreground.value, surface.value),
              greaterThanOrEqualTo(4.5),
              reason: '${foreground.key} on ${surface.key}',
            );
          }
        }
        expect(
          contrastRatio(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5),
          reason: 'onPrimary on primary',
        );
        expect(
          contrastRatio(scheme.onPrimaryContainer, scheme.primaryContainer),
          greaterThanOrEqualTo(4.5),
          reason: 'onPrimaryContainer on primaryContainer',
        );
      });
    }
  }

  for (final brightness in Brightness.values) {
    for (final palette in versePalettes) {
      test('${palette.name} ${brightness.name} field borders reach 3:1', () {
        final theme = verseTheme(brightness: brightness, palette: palette.name);
        final border = theme.inputDecorationTheme.enabledBorder!.borderSide;
        final fill = theme.inputDecorationTheme.fillColor!;
        expect(border.color.a, 1.0);
        expect(contrastRatio(border.color, fill), greaterThanOrEqualTo(3));
        expect(
          contrastRatio(border.color, theme.colorScheme.surface),
          greaterThanOrEqualTo(3),
        );
        expect(
          contrastRatio(border.color, theme.colorScheme.surfaceContainerHigh),
          greaterThanOrEqualTo(3),
        );
      });
    }
  }

  test('muted text is the color used for inactive navigation labels', () {
    for (final brightness in Brightness.values) {
      final theme = verseTheme(brightness: brightness, palette: 'navy');
      final style = theme.navigationBarTheme.labelTextStyle!.resolve({});
      expect(style!.color, verseMutedColor(brightness));
    }
  });
}
