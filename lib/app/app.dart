import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/chat/presentation/dasko_intro_screen.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';

class DaskoApp extends StatelessWidget {
  const DaskoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _DaskoAppShell());
  }
}

/// Consumes [themeProvider] and [localeProvider] so the shell follows both.
///
/// No explicit `Directionality` wrapper: `GlobalWidgetsLocalizations`, supplied
/// through `AppLocalizations.localizationsDelegates`, derives text direction
/// from the active locale (RTL for Arabic, LTR for English).
class _DaskoAppShell extends ConsumerWidget {
  const _DaskoAppShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeDataFor(appThemeMode),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DaskoIntroScreen(),
    );
  }
}
