import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/chat/presentation/dasko_intro_screen.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';

class DaskoApp extends StatelessWidget {
  const DaskoApp({super.key, this.home, this.overrides = const []});

  final Widget? home;
  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: _DaskoAppShell(home: home ?? const DaskoIntroScreen()),
    );
  }
}

/// Consumes [themeProvider] and [localeProvider] so the shell follows both.
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
      home: home,
    );
  }
}
