import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../application/theme_provider.dart';

/// Available theme choices, each mapping to an [AppThemeMode].
enum _ThemeOption {
  dark(
    mode: AppThemeMode.dark,
    label: AppStrings.themeDark,
    icon: Icons.dark_mode_outlined,
  ),
  light(
    mode: AppThemeMode.light,
    label: AppStrings.themeLight,
    icon: Icons.light_mode_outlined,
  ),
  neon(
    mode: AppThemeMode.neon,
    label: AppStrings.themeNeon,
    icon: Icons.auto_awesome_outlined,
  );

  const _ThemeOption({
    required this.mode,
    required this.label,
    required this.icon,
  });

  final AppThemeMode mode;
  final String label;
  final IconData icon;
}

/// Simple settings surface hosting the app-wide theme switch.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final appThemeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppStrings.settingsTitle,
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 12),
            child: Text(
              AppStrings.themeSectionTitle,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          for (final option in _ThemeOption.values)
            _ThemeOptionTile(option: option, selectedMode: appThemeMode),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends ConsumerWidget {
  const _ThemeOptionTile({required this.option, required this.selectedMode});

  final _ThemeOption option;
  final AppThemeMode selectedMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selected = option.mode == selectedMode;
    final glow = theme.extension<NeonGlow>();

    final tile = Material(
      color: selected
          ? colors.primaryContainer
          : colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => ref.read(themeProvider.notifier).setTheme(option.mode),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                option.icon,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  option.label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? colors.onPrimaryContainer
                        : colors.onSurface,
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
