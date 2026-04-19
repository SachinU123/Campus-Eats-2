import 'package:flutter/material.dart';
import 'package:campus_eats_ag/core/theme/app_colors.dart';

/// Consistent design tokens for Phase 8 polish.
/// Use these throughout the app instead of hardcoded values.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}

class AppRadius {
  AppRadius._();

  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 100;
}

class AppElevation {
  AppElevation._();

  static List<BoxShadow> card(bool isDark) => isDark
      ? []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ];

  static List<BoxShadow> chip(Color color, bool isDark) => isDark
      ? []
      : [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ];

  static List<BoxShadow> button(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

class AppCanteenStatus {
  AppCanteenStatus._();

  static const Color openColor = AppColors.success;
  static const Color pausedColor = AppColors.warning;
  static const Color closedColor = AppColors.error;

  static Color forStatus(String s) {
    switch (s) {
      case 'open':
        return openColor;
      case 'paused':
        return pausedColor;
      case 'closed':
        return closedColor;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  static IconData iconForStatus(String s) {
    switch (s) {
      case 'open':
        return Icons.check_circle_rounded;
      case 'paused':
        return Icons.pause_circle_rounded;
      case 'closed':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  static String labelForStatus(String s) {
    switch (s) {
      case 'open':
        return 'Open';
      case 'paused':
        return 'Paused';
      case 'closed':
        return 'Closed';
      default:
        return s;
    }
  }
}
