import 'dart:async';

import 'package:flutter/material.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme_mode.dart';
import '../domain/repositories/ai_engine.dart';
import '../domain/usecases/send_message.dart';
import '../features/chat/application/chat_notifier.dart';
import '../services/ai_engine/mock_ai_engine.dart';

/// Composition-root binding for the currently selected local demo engine.
/// Replace this binding when a real provider is deliberately introduced.
final aiEngineProvider = Provider<AiEngine>((ref) => MockAiEngine());

final sendMessageProvider = Provider<SendMessage>((ref) {
  return SendMessage(ref.watch(aiEngineProvider));
});

final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.watch(sendMessageProvider));
});

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
final themeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Palette + language persistence share the same async-restore pattern.
///
/// Supported languages; anything else falls back to Arabic.
const List<String> supportedLanguageCodes = <String>['ar', 'en'];

/// Holds the active [Locale], restores it on startup and persists changes.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale(AppConstants.defaultLocale)) {
    unawaited(_restore());
  }

  bool _isInitialized = false;
  Locale? _pending;

  /// True once the startup read has finished, successfully or not.
  bool get isInitialized => _isInitialized;

  static bool isSupported(Locale locale) =>
      supportedLanguageCodes.contains(locale.languageCode);

  Future<void> _restore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(AppConstants.keyLocale);
      if (_pending == null && stored != null && isSupported(Locale(stored))) {
        state = Locale(stored);
      }
    } catch (_) {
      // Storage is optional; keep the Arabic default.
    } finally {
      _isInitialized = true;
      final pending = _pending;
      _pending = null;
      if (pending != null) await _persist(pending);
    }
  }

  /// Applies a supported [locale]; unsupported values are ignored and Arabic
  /// stays active.
  Future<void> setLocale(Locale locale) async {
    if (!isSupported(locale)) return;
    state = locale;
    if (!_isInitialized) {
      _pending = locale;
      return;
    }
    await _persist(locale);
  }

  Future<void> _persist(Locale locale) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(AppConstants.keyLocale, locale.languageCode);
    } catch (_) {
      // Persisting is best-effort; the in-memory selection still applies.
    }
  }
}

/// Active app language; defaults to Arabic and rejects unsupported locales.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
