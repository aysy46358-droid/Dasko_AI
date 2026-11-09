import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_theme_mode.dart';
import '../../../l10n/app_localizations.dart';

/// Palette choices; the label is resolved through the active localizations.
enum _ThemeOption {
  dark(mode: AppThemeMode.dark, icon: Icons.dark_mode_outlined),
  light(mode: AppThemeMode.light, icon: Icons.light_mode_outlined),
  neon(mode: AppThemeMode.neon, icon: Icons.auto_awesome_outlined);

  const _ThemeOption({required this.mode, required this.icon});

  final AppThemeMode mode;
  final IconData icon;
}

String _themeLabel(AppLocalizations l10n, AppThemeMode mode) {
  return switch (mode) {
    AppThemeMode.dark => l10n.themeDark,
    AppThemeMode.light => l10n.themeLight,
    AppThemeMode.neon => l10n.themeNeon,
  };
}

/// Settings surface: palette switch plus the app language switch.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final appThemeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider).locale;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.settingsTitle, style: theme.textTheme.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SectionLabel(text: l10n.themeSectionTitle),
          for (final option in _ThemeOption.values)
            _OptionTile(
              icon: option.icon,
              label: _themeLabel(l10n, option.mode),
              selected: option.mode == appThemeMode,
              onTap: () =>
                  ref.read(themeProvider.notifier).setTheme(option.mode),
            ),
          const SizedBox(height: 14),
          _SectionLabel(text: l10n.languageSectionTitle),
          _OptionTile(
            icon: Icons.language,
            label: l10n.languageArabic,
            selected: locale.languageCode == 'ar',
            onTap: () => ref.read(localeProvider.notifier).setLocale(
                  const Locale('ar'),
                ),
          ),
          _OptionTile(
            icon: Icons.translate,
            label: l10n.languageEnglish,
            selected: locale.languageCode == 'en',
            onTap: () => ref.read(localeProvider.notifier).setLocale(
                  const Locale('en'),
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 12),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final glow = theme.extension<NeonGlow>();

    final tile = Material(
      color:
          selected ? colors.primaryContainer : colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        selected ? colors.onPrimaryContainer : colors.onSurface,
                  ),
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: colors.primary),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: selected && glow != null
          ? DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: glow.borderGlow,
              ),
              child: tile,
            )
          : tile,
    );
  }
}
