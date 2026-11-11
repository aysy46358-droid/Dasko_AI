import 'dart:async';

import 'package:flutter/material.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/app_constants.dart';
import 'theme/app_theme_mode.dart';

/// Storage key for the persisted palette selection.
const String themePreferenceKey = 'theme_mode';

/// Holds the selected palette, restores it on startup and persists changes.
///
/// Writes are gated behind [isInitialized] so a fast user tap cannot clobber
/// the stored choice with the default that is still on screen while the
/// asynchronous startup read is in flight.
class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.neon) {
    unawaited(_restore());
  }

  bool _isInitialized = false;
  AppThemeMode? _pendingPersist;

  /// True once the startup read has finished, successfully or not.
  bool get isInitialized => _isInitialized;

  /// Reads the saved palette. A missing, unreadable or unknown value leaves
  /// the neon default in place so storage problems cannot block startup.
  Future<void> _restore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(themePreferenceKey);
      // A choice made before this read finished wins over the stored value.
      if (_pendingPersist == null && stored != null) {
        for (final mode in AppThemeMode.values) {
          if (mode.name == stored) {
            state = mode;
            break;
          }
        }
      }
    } catch (_) {
      // Storage is optional; keep the in-memory default.
    } finally {
      _isInitialized = true;
      final pending = _pendingPersist;
      _pendingPersist = null;
      if (pending != null) await _persist(pending);
    }
  }

  /// Applies [mode] immediately, then persists it for the next launch.
  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    if (!_isInitialized) {
      _pendingPersist = mode;
      return;
    }
    await _persist(mode);
  }

  Future<void> _persist(AppThemeMode mode) async {
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
final themeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

/// Supported languages; anything else falls back to Arabic.
const List<String> supportedLanguageCodes = <String>['ar', 'en'];

/// Active app language; defaults to Arabic and rejects unsupported locales.
class LocaleState {
  const LocaleState({required this.locale, required this.isInitialized});

  final Locale locale;
  final bool isInitialized;
}

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

/// Loads and persists the app language while preserving the user's latest
/// choice if it changes before the initial preferences read completes.
class LocaleNotifier extends StateNotifier<LocaleState> {
  LocaleNotifier({SharedPreferencesLoader? loadPreferences})
    : _loadPreferences = loadPreferences ?? SharedPreferences.getInstance,
      super(
        const LocaleState(
          locale: Locale(AppConstants.defaultLocale),
          isInitialized: false,
        ),
      ) {
    unawaited(_restore());
  }

  final SharedPreferencesLoader _loadPreferences;
  Locale? _pending;
  Future<void> _writes = Future<void>.value();

  static bool isSupported(Locale locale) =>
      supportedLanguageCodes.contains(locale.languageCode);

  Future<void> _restore() async {
    String? stored;
    try {
      final preferences = await _loadPreferences();
      stored = preferences.getString(AppConstants.keyLocale);
    } catch (_) {
      // Storage is optional; the default locale still allows startup.
    }

    if (!mounted) return;

    final pending = _pending;
    final restored = stored == null ? null : Locale(stored);
    final locale =
        pending ??
        (restored != null && isSupported(restored) ? restored : state.locale);

    _pending = null;
    state = LocaleState(locale: locale, isInitialized: true);
    if (pending != null) await _persist(pending);
  }

  /// Applies a supported [locale] immediately and persists it best-effort.
  Future<void> setLocale(Locale locale) async {
    if (!isSupported(locale)) return;

    final isInitialized = state.isInitialized;
    state = LocaleState(locale: locale, isInitialized: isInitialized);
    if (!isInitialized) {
      _pending = locale;
      return;
    }

    await _persist(locale);
  }

  /// Serializes writes so rapid selections cannot leave an older value stored.
  Future<void> _persist(Locale locale) {
    _writes = _writes.then((_) async {
      try {
        final preferences = await _loadPreferences();
        await preferences.setString(
          AppConstants.keyLocale,
          locale.languageCode,
        );
      } catch (_) {
        // Persisting is best-effort; the in-memory selection still applies.
      }
    });
    return _writes;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, LocaleState>((
  ref,
) {
  return LocaleNotifier();
});
