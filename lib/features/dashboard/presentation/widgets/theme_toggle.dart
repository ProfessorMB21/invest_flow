import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investflow/core/providers/theme_provider.dart';

/// A button that cycles through theme modes: light → dark → system → light
class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  IconData _getIconForThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getTooltipForThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Switch to dark mode';
      case ThemeMode.dark:
        return 'Switch to system mode';
      case ThemeMode.system:
        return 'Switch to light mode';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeModeProvider);
    final currentThemeMode = themeNotifier.themeMode;

    return IconButton(
      icon: Icon(
        _getIconForThemeMode(currentThemeMode),
        color: Theme.of(context).iconTheme.color,
      ),
      tooltip: _getTooltipForThemeMode(currentThemeMode),
      onPressed: () => themeNotifier.cycleThemeMode(),
    );
  }
}
