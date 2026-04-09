/// AppColors - Centralized color constants for the InvestFlow app
library;

import 'package:flutter/material.dart';

/// AppColors provides a centralized location for all color definitions in the app.
class AppColors {
  AppColors._(); // Prevent instantiation

  // Primary Brand Colors
  static const Color primary = Color(0xFF6C63FF); // Purple
  static const Color primaryDark = Color(0xFF4840B8); // Darker purple
  static const Color primaryLight = Color(0xFF9D96FF); // Lighter purple

  // Success/Error Colors
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEA4335);
  static const Color info = Color(0xFF00BCD4);

  // Neutral Colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF757575);
  static const Color greyDark = Color(0xFF616161);
  static const Color greyLight = Color(0xFFBDBDBD);
  static const Color greyLighter = Color(0xFFE0E0E0);
  static const Color greyDarkest = Color(0xFF212121);

  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF9F9F9);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);

  // Card Colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE0E0E0);

  // Icon Colors
  static const Color iconPrimary = Color(0xFF6C63FF);
  static const Color iconSecondary = Color(0xFF757575);

  // Gradient Colors for special effects
  static const List<Color> gradientPrimary = [
    primary,
    primaryDark,
  ];

  static const List<Color> gradientSuccess = [
    success,
    Color(0xFF00E676),
  ];

  static const List<Color> gradientWarning = [
    warning,
    Color(0xFFFFE57F),
  ];

  // Helper methods for color manipulation
  static Color primaryWithOpacity(double opacity) =>
      primary.withOpacity(opacity);

  static Color errorWithOpacity(double opacity) =>
      error.withOpacity(opacity);

  static Color successWithOpacity(double opacity) =>
      success.withOpacity(opacity);
}
