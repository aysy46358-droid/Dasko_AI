import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_routes.dart';
import '../core/providers.dart';
import '../core/theme/app_theme.dart';
import '../domain/repositories/ai_engine.dart';
import '../features/chat/application/chat_providers.dart';
import '../features/chat/presentation/dasko_intro_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../l10n/app_localizations.dart';
import '../services/ai_engine/mock_ai_engine.dart';

class DaskoApp extends StatelessWidget {
  const DaskoApp({
    super.key,
    this.home,
    this.overrides = const [],
    this.aiEngine = const MockAiEngine(),
  });

  final Widget? home;
  final List<Override> overrides;
  final AiEngine aiEngine;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [aiEngineProvider.overrideWithValue(aiEngine), ...overrides],
      child: _DaskoAppShell(home: home ?? const DaskoIntroScreen()),
    );
  }
}

/// Consumes shared theme and locale state and registers feature routes.
///
/// No explicit `Directionality` wrapper: `GlobalWidgetsLocalizations`, supplied
/// through `AppLocalizations.localizationsDelegates`, derives text direction
/// from the active locale (RTL for Arabic, LTR for English).
class _DaskoAppShell extends ConsumerWidget {
  const _DaskoAppShell({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode = ref.watch(themeProvider);
    final localeState = ref.watch(localeProvider);

    if (!localeState.isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeDataFor(appThemeMode),
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              key: ValueKey<String>('locale-restoring'),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeDataFor(appThemeMode),
      locale: localeState.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routes: <String, WidgetBuilder>{
        AppRoutes.settings: (_) => const SettingsScreen(),
      },
      home: home,
    );
  }
}
