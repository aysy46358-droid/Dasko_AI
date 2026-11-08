import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Selectable app palettes.
///
/// `neon` is the product's signature look: the dark canvas plus cyan/violet
/// glow accents. `light` and `dark` are the plain Material variants.
enum AppThemeMode { light, dark, neon }

/// Storage key for the persisted palette selection.
const String themePreferenceKey = 'theme_mode';

/// Holds the selected palette, restores it on startup and persists changes.
class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.neon) {
    unawaited(_restore());
  }

  /// Reads the saved palette. A missing, unreadable or unknown value leaves
  /// the neon default in place so storage problems cannot block startup.
  Future<void> _restore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(themePreferenceKey);
      if (stored == null) return;
      for (final mode in AppThemeMode.values) {
        if (mode.name == stored) {
          state = mode;
          return;
        }
      }
    } catch (_) {
      // Storage is optional; keep the in-memory default.
    }
  }

  /// Applies [mode] immediately, then persists it for the next launch.
  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(themePreferenceKey, mode.name);
    } catch (_) {
      // Persisting is best-effort; the in-memory selection still applies.
    }
  }
}

/// App-wide theme selection consumed by `MaterialApp.theme`.
/// Defaults to [AppThemeMode.neon] because that is the shipped aesthetic.
final themeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier();
});
