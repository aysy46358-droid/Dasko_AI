import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF00E5FF);
  static const Color secondary = Color(0xFF7C4DFF);
  static const Color background = Color(0xFF0B0F19);
  static const Color surface = Color(0xFF111827);
  static const Color userBubble = Color(0xFF10263A);
  static const Color aiBubble = Color(0xFF171326);

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
}
