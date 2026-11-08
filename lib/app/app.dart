import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../features/chat/presentation/dasko_intro_screen.dart';
import 'providers.dart';

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

/// Consumes [themeProvider] so `MaterialApp.themeMode` follows the settings.
class _DaskoAppShell extends ConsumerWidget {
  const _DaskoAppShell({this.robotViewerOverride});

  final Widget? robotViewerOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
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
