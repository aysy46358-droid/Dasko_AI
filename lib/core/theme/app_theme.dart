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

  /// Light counterpart of [dark].
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

  /// Cyan→violet glow applied to neon text styles.
  static const List<Shadow> neonTextGlow = <Shadow>[
    Shadow(color: Color(0xAA00E5FF), blurRadius: 14),
    Shadow(color: Color(0x887C4DFF), blurRadius: 26),
  ];

  /// Cyan→violet glow applied behind neon borders and floating surfaces.
  static const List<BoxShadow> neonBorderGlow = <BoxShadow>[
    BoxShadow(color: Color(0x6600E5FF), blurRadius: 18),
    BoxShadow(color: Color(0x447C4DFF), blurRadius: 28),
  ];

  /// Glowing text style; defaults reproduce the app wordmark treatment.
  static TextStyle neonText({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w700,
    Color color = primary,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      shadows: neonTextGlow,
    );
  }

  /// Signature palette: the dark canvas lit by cyan and violet neon.
  static ThemeData get neon {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: neonText(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
        iconTheme: const IconThemeData(color: primary),
        actionsIconTheme: const IconThemeData(color: primary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF061018),
          shadowColor: primary,
          elevation: 12,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: primary),
      ),
      dividerTheme: const DividerThemeData(color: Color(0x447C4DFF)),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: Color(0x5500E5FF),
        selectionHandleColor: primary,
      ),
    );
  }
}
