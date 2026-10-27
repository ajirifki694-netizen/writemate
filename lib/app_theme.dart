import 'package:flutter/material.dart';

/// Theme mode aktif. Nilai ini dipakai oleh SettingsPage dan WriteMateApp.
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

const Color _brandPurple = Color(0xFF8C6598);
const Color _lightBackground = Color(0xFFFFF9FC);
const Color _darkBackground = Color(0xFF171318);

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _brandPurple,
    brightness: Brightness.light,
    surface: _lightBackground,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: _lightBackground,
    fontFamily: 'Arial',
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFCFE),
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _lightBackground,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFC9A0D5),
    brightness: Brightness.dark,
    surface: _darkBackground,
  ).copyWith(
    primary: const Color(0xFFD6B2E0),
    onPrimary: const Color(0xFF321B3A),
    secondary: const Color(0xFFC9A0D5),
    onSecondary: const Color(0xFF2D1834),
    secondaryContainer: const Color(0xFF392940),
    onSecondaryContainer: const Color(0xFFF4E5F8),
    surface: _darkBackground,
    onSurface: const Color(0xFFF3EAF4),
    surfaceContainerLowest: const Color(0xFF171318),
    surfaceContainerLow: const Color(0xFF211B23),
    surfaceContainer: const Color(0xFF28212B),
    surfaceContainerHigh: const Color(0xFF302834),
    surfaceContainerHighest: const Color(0xFF3A3140),
    onSurfaceVariant: const Color(0xFFD4C7D8),
    outline: const Color(0xFF8C7C91),
    outlineVariant: const Color(0xFF514456),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: _darkBackground,
    fontFamily: 'Arial',
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _darkBackground,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF211B23),
      indicatorColor: scheme.secondaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
        color: states.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
      )),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
