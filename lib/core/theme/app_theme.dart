import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF8AB4F8);
  static const Color background = Colors.black;
  static const Color surface = Color(0xFF1A1A1A);
  static const Color userBubble = Color(0xFF1F3A5F);
  static const Color aiBubble = Color(0xFF1A1A1A);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),
    );
  }
}