import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF00E5FF);
  static const Color secondary = Color(0xFF7C4DFF);
  static const Color background = Color(0xFF0B0F19);
  static const Color surface = Color(0xFF111827);
  static const Color userBubble = Color(0xFF10263A);
  static const Color aiBubble = Color(0xFF171326);
  static const Color lightBackground = Color(0xFFF4F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  // Darkened neon keeps contrast readable on the light background.
  static const Color primaryDark = Color(0xFF007A8F);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: Color(0x5500E5FF),
        selectionHandleColor: primary,
      ),
    );
  }

  /// Light counterpart of [dark]. Required for `ThemeMode.light` and
  /// `ThemeMode.system` to change anything: Flutter falls back to `theme`
  /// when no `darkTheme`/light variant is supplied.
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryDark,
        secondary: secondary,
        surface: lightSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryDark,
        selectionColor: Color(0x3300B8CC),
        selectionHandleColor: primaryDark,
      ),
    );
  }
}
