import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_ui_state.dart';

void main() {
  test('Singbook defaults to the navy palette', () {
    expect(const VerseUiState().palette, 'navy');
    expect(versePalettes.first.name, 'navy');
  });

  test('navy light theme uses parchment and dark theme uses amber primary', () {
    final light = verseTheme(brightness: Brightness.light, palette: 'navy');
    final dark = verseTheme(brightness: Brightness.dark, palette: 'navy');

    expect(light.colorScheme.primary, const Color(0xFF315D82));
    expect(light.scaffoldBackgroundColor, const Color(0xFFF7F3E9));
    expect(light.cardTheme.color, const Color(0xFFFFFDF8));
    expect(dark.scaffoldBackgroundColor, const Color(0xFF081B33));
    expect(dark.colorScheme.primary, const Color(0xFFEFB746));
  });

  test('alternate palettes remain available', () {
    expect(
      versePalettes.map((palette) => palette.name),
      containsAll(['sage', 'ocean', 'clay', 'plum']),
    );
  });

  test('alternate dark palettes keep their own accent color', () {
    final navy = verseTheme(brightness: Brightness.dark, palette: 'navy');
    final sage = verseTheme(brightness: Brightness.dark, palette: 'sage');

    expect(navy.colorScheme.primary, const Color(0xFFEFB746));
    expect(sage.colorScheme.primary, isNot(navy.colorScheme.primary));
  });
}
