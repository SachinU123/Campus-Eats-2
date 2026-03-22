import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand palette — deep green
  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF003300);
  static const Color accent = Color(0xFF66BB6A);
  static const Color accentLight = Color(0xFFA5D6A7);

  // Surface / Background
  static const Color backgroundLight = Color(0xFFF5F6F0);
  static const Color backgroundDark = Color(0xFF0D1B0E);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A2B1B);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E2F1F);

  // Text
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textPrimaryDark = Color(0xFFF0F0F0);
  static const Color textSecondaryLight = Color(0xFF555555);
  static const Color textSecondaryDark = Color(0xFFAAAAAA);
  static const Color textHintLight = Color(0xFF999999);
  static const Color textHintDark = Color(0xFF666666);

  // Status
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57F17);
  static const Color error = Color(0xFFB71C1C);
  static const Color info = Color(0xFF01579B);

  // Order status chips
  static const Color statusPreparing = Color(0xFFF57F17);
  static const Color statusReady = Color(0xFF1565C0);
  static const Color statusVerified = Color(0xFF6A1B9A);
  static const Color statusCollected = Color(0xFF2E7D32);
  static const Color statusScheduled = Color(0xFF00838F);

  // Veg badge
  static const Color vegGreen = Color(0xFF2E7D32);
  static const Color nonVegRed = Color(0xFFB71C1C);

  // Divider / Border
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF2A3D2B);

  // Shimmer
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Offline banner
  static const Color offlineBanner = Color(0xFFC62828);
  static const Color syncingBanner = Color(0xFF1565C0);
  static const Color syncedBanner = Color(0xFF2E7D32);
}
