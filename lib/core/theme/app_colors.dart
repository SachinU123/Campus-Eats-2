import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Premium brand palette — elegant deep pine green
  static const Color primary = Color(0xFF194D33);
  static const Color primaryLight = Color(0xFF2D6A4F);
  static const Color primaryDark = Color(0xFF0D2818);
  static const Color accent = Color(0xFF40916C);
  static const Color accentLight = Color(0xFF95D5B2);

  // Surface / Background
  static const Color backgroundLight = Color(0xFFFAF9F6); // Soft off-white
  static const Color backgroundDark = Color(0xFF121212); // True standard dark background
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1A1A1A);

  // Text
  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryLight = Color(0xFF6B6B70);
  static const Color textSecondaryDark = Color(0xFFA0A0A5);
  static const Color textHintLight = Color(0xFF9E9E9E);
  static const Color textHintDark = Color(0xFF757575);

  // Status Colors (Refined & Semantic)
  static const Color success = Color(0xFF2D6A4F);
  static const Color warning = Color(0xFFE67E22);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1976D2);

  // Order status semantic
  static const Color statusPreparing = Color(0xFFE67E22);
  static const Color statusReady = Color(0xFF1976D2);
  static const Color statusVerified = Color(0xFF7E57C2);
  static const Color statusCollected = Color(0xFF2D6A4F);
  static const Color statusScheduled = Color(0xFF00ACC1);

  // Veg/Non-Veg Badges
  static const Color vegGreen = Color(0xFF2D6A4F);
  static const Color nonVegRed = Color(0xFFD32F2F);

  // Divider / Border
  static const Color dividerLight = Color(0xFFE5E5EA);
  static const Color dividerDark = Color(0xFF2C2C2E);

  // Shimmer
  static const Color shimmerBaseLight = Color(0xFFE0E0E0);
  static const Color shimmerHighlightLight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF424242);
  static const Color shimmerHighlightDark = Color(0xFF616161);

  // Banners
  static const Color offlineBanner = Color(0xFFD32F2F);
  static const Color syncingBanner = Color(0xFF1976D2);
  static const Color syncedBanner = Color(0xFF2D6A4F);
}
