import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_strings.dart';

const _cyan = Color(0xFF00E5FF);

/// Available theme choices, each mapping to a [ThemeMode].
enum _ThemeOption {
  dark(
    mode: ThemeMode.dark,
    label: AppStrings.themeDark,
    icon: Icons.dark_mode_outlined,
  ),
  light(
    mode: ThemeMode.light,
    label: AppStrings.themeLight,
    icon: Icons.light_mode_outlined,
  ),
  system(
    mode: ThemeMode.system,
    label: AppStrings.themeSystem,
    icon: Icons.brightness_auto_outlined,
  );

  const _ThemeOption({
    required this.mode,
    required this.label,
    required this.icon,
  });

  final ThemeMode mode;
  final String label;
  final IconData icon;
}

/// Simple settings surface hosting the app-wide theme switch.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        title: const Text(
          AppStrings.settingsTitle,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xDD0B0F19),
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 6, 4, 12),
            child: Text(
              AppStrings.themeSectionTitle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: _cyan,
              ),
            ),
          ),
          for (final option in _ThemeOption.values)
            _ThemeOptionTile(option: option, selectedMode: themeMode),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends ConsumerWidget {
  const _ThemeOptionTile({required this.option, required this.selectedMode});

  final _ThemeOption option;
  final ThemeMode selectedMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = option.mode == selectedMode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? const Color(0xFF10263A) : const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => ref.read(themeProvider.notifier).state = option.mode,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(option.icon, color: selected ? _cyan : Colors.white54),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (selected) const Icon(Icons.check_circle, color: _cyan),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
