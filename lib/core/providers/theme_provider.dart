import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

// Theme notifier state class
class ThemeNotifierState extends ChangeNotifier {
  ThemeNotifierState(this._themeMode) {
    notifyListeners();
  }

  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemDefault => _themeMode == ThemeMode.system;

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void followSystemTheme() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }

  /// Cycles through theme modes: light → dark → system → light
  void cycleThemeMode() {
    switch (_themeMode) {
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.system;
        break;
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
        break;
    }
    notifyListeners();
  }
}

// Provider - use ChangeNotifierProvider so UI rebuilds when theme changes
final themeModeProvider = ChangeNotifierProvider<ThemeNotifierState>((ref) => ThemeNotifierState(ThemeMode.system));
