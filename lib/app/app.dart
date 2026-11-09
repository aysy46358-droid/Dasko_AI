import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../features/chat/presentation/dasko_intro_screen.dart';
import '../features/settings/application/theme_provider.dart';

class DaskoApp extends StatelessWidget {
  const DaskoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _DaskoAppShell());
  }
}

/// Consumes [themeProvider] so `MaterialApp.theme` follows the settings.
class _DaskoAppShell extends ConsumerWidget {
  const _DaskoAppShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeDataFor(appThemeMode),
      locale: const Locale(AppConstants.defaultLocale),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const DaskoIntroScreen(),
    );
  }
}
