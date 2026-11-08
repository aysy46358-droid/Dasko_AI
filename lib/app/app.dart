import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../features/chat/presentation/dasko_intro_screen.dart';
import '../features/settings/application/theme_provider.dart';

class DaskoApp extends StatelessWidget {
  const DaskoApp({super.key, this.robotViewerOverride});

  final Widget? robotViewerOverride;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: _DaskoAppShell(robotViewerOverride: robotViewerOverride),
    );
  }
}

/// Maps the selected [AppThemeMode] to the palette used by `MaterialApp`.
ThemeData _themeDataFor(AppThemeMode mode) {
  return switch (mode) {
    AppThemeMode.light => AppTheme.light,
    AppThemeMode.dark => AppTheme.dark,
    AppThemeMode.neon => AppTheme.neon,
  };
}

/// Consumes [themeProvider] so `MaterialApp.theme` follows the settings.
class _DaskoAppShell extends ConsumerWidget {
  const _DaskoAppShell({this.robotViewerOverride});

  final Widget? robotViewerOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: _themeDataFor(appThemeMode),
      locale: const Locale(AppConstants.defaultLocale),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: DaskoIntroScreen(robotViewerOverride: robotViewerOverride),
    );
  }
}
