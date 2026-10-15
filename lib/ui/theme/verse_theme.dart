import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VersePalette {
  const VersePalette({
    required this.name,
    required this.seed,
    required this.paper,
    required this.ink,
  });
  final String name;
  final Color seed, paper, ink;
}

const versePalettes = <VersePalette>[
  VersePalette(
    name: 'navy',
    seed: Color(0xFF315D82),
    paper: Color(0xFFF7F3E9),
    ink: Color(0xFF081B33),
  ),
  VersePalette(
    name: 'sage',
    seed: Color(0xFF286451),
    paper: Color(0xFFF7F7F2),
    ink: Color(0xFF203A31),
  ),
  VersePalette(
    name: 'ocean',
    seed: Color(0xFF315F88),
    paper: Color(0xFFF4F7FA),
    ink: Color(0xFF233A4E),
  ),
  VersePalette(
    name: 'clay',
    seed: Color(0xFF985B3A),
    paper: Color(0xFFFAF5F1),
    ink: Color(0xFF44352E),
  ),
  VersePalette(
    name: 'plum',
    seed: Color(0xFF755178),
    paper: Color(0xFFF8F4F8),
    ink: Color(0xFF3F3142),
  ),
];

/// Secondary text and inactive navigation color. Both values keep at least a
/// 4.5:1 contrast ratio against every palette's surface and card color.
Color verseMutedColor(Brightness brightness) => brightness == Brightness.light
    ? const Color(0xFF50647A)
    : const Color(0xFFBAC7D2);

/// Fill of cards and text fields.
Color verseCardColor(Brightness brightness) => brightness == Brightness.light
    ? const Color(0xFFFFFDF8)
    : const Color(0xFF102743);

ThemeData verseTheme({
  required Brightness brightness,
  required String palette,
  String fontFamily = 'sans-serif',
}) {
  final colors = versePalettes.firstWhere(
    (value) => value.name == palette,
    orElse: () => versePalettes.first,
  );
  final dark = brightness == Brightness.dark;
  final generatedScheme = ColorScheme.fromSeed(
    seedColor: colors.seed,
    brightness: brightness,
    surface: brightness == Brightness.light
        ? colors.paper
        : const Color(0xFF081B33),
  );
  final navyDark = dark && colors.name == 'navy';
  final navyLight = !dark && colors.name == 'navy';
  final scheme = generatedScheme.copyWith(
    primary: navyDark
        ? const Color(0xFFEFB746)
        : navyLight
        ? const Color(0xFF315D82)
        : generatedScheme.primary,
    onPrimary: navyDark
        ? const Color(0xFF081B33)
        : navyLight
        ? Colors.white
        : generatedScheme.onPrimary,
    secondary: dark ? const Color(0xFF7897B4) : const Color(0xFF3F6585),
    primaryContainer: navyDark
        ? const Color(0xFF59451B)
        : navyLight
        ? const Color(0xFFDCE8F1)
        : generatedScheme.primaryContainer,
    onPrimaryContainer: navyDark
        ? const Color(0xFFFFE2A2)
        : navyLight
        ? const Color(0xFF183B58)
        : generatedScheme.onPrimaryContainer,
    surface: dark ? const Color(0xFF081B33) : colors.paper,
    onSurface: dark ? const Color(0xFFF7F3E9) : colors.ink,
  );
  final textColor = brightness == Brightness.light
      ? colors.ink
      : const Color(0xFFF7F3E9);
  final muted = verseMutedColor(brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: fontFamily,
    textTheme: ThemeData(
      brightness: brightness,
    ).textTheme.apply(bodyColor: textColor, displayColor: textColor),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: textColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: scheme.surface,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: scheme.surface,
        systemNavigationBarIconBrightness: dark
            ? Brightness.light
            : Brightness.dark,
      ),
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primary.withValues(alpha: .12),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 14,
          fontFamily: fontFamily,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? scheme.primary : muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 28,
          color: states.contains(WidgetState.selected) ? scheme.primary : muted,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      selectedIconTheme: IconThemeData(size: 28, color: scheme.primary),
      unselectedIconTheme: IconThemeData(size: 28, color: muted),
      selectedLabelTextStyle: TextStyle(
        fontSize: 14,
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        color: scheme.primary,
      ),
      unselectedLabelTextStyle: TextStyle(
        fontSize: 14,
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
        color: muted,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: brightness == Brightness.light
          ? const Color(0xFFFFFDF8)
          : const Color(0xFF102743),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: .45),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: brightness == Brightness.light
          ? const Color(0xFFFFFDF8)
          : const Color(0xFF102743),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .35)),
      ),
      margin: EdgeInsets.zero,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: muted,
      textColor: textColor,
      minVerticalPadding: 10,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: .4),
      thickness: 1,
      space: 1,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: .12),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
